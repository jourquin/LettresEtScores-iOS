#!/bin/zsh
#
# install-renew-ios.sh
# Installation automatique de la procédure de renouvellement Wi‑Fi.
# Version 1.0.0
#
set -euo pipefail

INSTALLER_VERSION="1.0.0"
LAUNCHD_LABEL="be.bartjourquin.lettresetcores.renew-ios"
INTERVAL_SECONDS=1800
RUN_TEST=1
UNINSTALL=0
DEVICE_OVERRIDE=""
CERT_OVERRIDE=""
ACCEPT_NEW_CERT=0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RENEW_SCRIPT="$SCRIPT_DIR/renew-ios-wifi.sh"
PROJECT="$PROJECT_ROOT/LettresEtScores.xcodeproj"
SCHEME="LettresEtScores"

CONFIG_DIR="$HOME/.config/lettres-et-scores"
CONFIG_FILE="$CONFIG_DIR/renew-ios.conf"
LAUNCHAGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$LAUNCHAGENT_DIR/${LAUNCHD_LABEL}.plist"
STATE_DIR="$HOME/.local/state/lettres-et-scores"

log() { print -r -- "[InstallRenew] $*"; }
die() { print -u2 -r -- "[InstallRenew] ERREUR: $*"; exit 1; }

usage() {
    cat <<EOF
install-renew-ios.sh v${INSTALLER_VERSION}

Usage:
  install-renew-ios.sh [options]

Options:
  --device ID       Force un CoreDevice ID précis.
  --cert SHA1       Force l'empreinte SHA-1 du certificat.
  --no-test         N'exécute pas le premier renouvellement.
  --accept-new-cert Accepte explicitement un nouveau certificat sans question.
  --uninstall       Désinstalle le LaunchAgent et la configuration locale.
  --version         Affiche la version.
  -h, --help        Affiche cette aide.
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --device)
            shift; (( $# > 0 )) || die "--device nécessite une valeur."
            DEVICE_OVERRIDE="$1"
            ;;
        --cert)
            shift; (( $# > 0 )) || die "--cert nécessite une valeur."
            CERT_OVERRIDE="$1"
            ;;
        --no-test) RUN_TEST=0 ;;
        --accept-new-cert) ACCEPT_NEW_CERT=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --version) print -r -- "$INSTALLER_VERSION"; exit 0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Option inconnue: $1" ;;
    esac
    shift
done

backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local stamp="$(date '+%Y%m%d-%H%M%S')"
        cp -p "$file" "${file}.bak-${stamp}"
        log "Sauvegarde : ${file}.bak-${stamp}"
    fi
}

if (( UNINSTALL )); then
    launchctl bootout "gui/$(id -u)" "$PLIST_FILE" >/dev/null 2>&1 || true
    [[ -f "$PLIST_FILE" ]] && rm -f "$PLIST_FILE"
    [[ -f "$CONFIG_FILE" ]] && rm -f "$CONFIG_FILE"
    log "LaunchAgent et configuration locale supprimés."
    log "État conservé dans $STATE_DIR (suppression facultative)."
    exit 0
fi

[[ "$(uname -s)" == "Darwin" ]] || die "Cet installateur nécessite macOS."
[[ -f "$RENEW_SCRIPT" ]] || die "Script absent : $RENEW_SCRIPT"
[[ -d "$PROJECT" ]] || die "Projet Xcode absent : $PROJECT"

for cmd in xcrun xcodebuild security launchctl plutil python3; do
    command -v "$cmd" >/dev/null 2>&1 || die "Commande requise introuvable : $cmd"
done

chmod +x "$RENEW_SCRIPT"
RENEW_VERSION="$("$RENEW_SCRIPT" --version 2>/dev/null || true)"
[[ -n "$RENEW_VERSION" ]] || die "Impossible de déterminer la version de renew-ios-wifi.sh."

log "Installateur v${INSTALLER_VERSION}"
log "renew-ios-wifi.sh v${RENEW_VERSION}"
log "Dépôt : $PROJECT_ROOT"

# Si une installation existe déjà, on privilégie ses choix afin que
# l'installateur soit idempotent et ne change pas silencieusement d'appareil
# ou de certificat.
EXISTING_DEVICE_ID=""
EXISTING_CERT_SHA1=""

if [[ -f "$CONFIG_FILE" ]]; then
    EXISTING_DEVICE_ID="$(
        sed -nE 's/^DEVICE_ID="([^"]*)".*/\1/p' "$CONFIG_FILE" | head -n 1
    )"
    EXISTING_CERT_SHA1="$(
        sed -nE 's/^EXPECTED_SIGNING_CERT_SHA1="([^"]*)".*/\1/p' "$CONFIG_FILE" | head -n 1
    )"
fi

DEVICE_JSON="$(mktemp -t lettres-et-scores-devices).json"
CANDIDATES="$(mktemp -t lettres-et-scores-candidates)"
IDENTITIES="$(mktemp -t lettres-et-scores-identities)"
trap 'rm -f "$DEVICE_JSON" "$CANDIDATES" "$IDENTITIES"' EXIT

log "Recherche des appareils iOS connus de CoreDevice…"

xcrun devicectl list devices --json-output "$DEVICE_JSON" >/dev/null 2>&1 \
    || die "devicectl n'a pas pu lister les appareils."

python3 - "$DEVICE_JSON" > "$CANDIDATES" <<'PY'
import json, sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

for d in data.get("result", {}).get("devices", []):
    conn = d.get("connectionProperties") or {}
    props = d.get("deviceProperties") or {}
    hw = d.get("hardwareProperties") or {}

    platform = str(hw.get("platform") or "").lower()
    reality = str(hw.get("reality") or "").lower()
    dtype = str(hw.get("deviceType") or "").lower()
    transport = str(conn.get("transportType") or "")

    if reality == "simulated" or transport == "sameMachine":
        continue
    if "ios" not in platform and "iphone" not in dtype and "ipad" not in dtype:
        continue

    identifier = str(d.get("identifier") or "")
    if not identifier:
        continue

    name = str(props.get("name") or "Appareil iOS")
    os_version = str(props.get("osVersionNumber") or props.get("osVersion") or "")
    udid = str(hw.get("udid") or hw.get("deviceUDID") or d.get("udid") or "")
    pairing = str(conn.get("pairingState") or "")
    tunnel = str(conn.get("tunnelState") or "")

    fields = [identifier, udid, name, os_version, pairing, tunnel]
    print("\t".join(v.replace("\t", " ") for v in fields))
PY

select_device() {
    local count="$(grep -c '.' "$CANDIDATES" || true)"
    (( count > 0 )) || die "Aucun appareil iOS physique détecté."

    if [[ -n "$DEVICE_OVERRIDE" ]]; then
        local line="$(awk -F '\t' -v id="$DEVICE_OVERRIDE" '$1 == id {print; exit}' "$CANDIDATES")"
        [[ -n "$line" ]] || die "CoreDevice ID introuvable : $DEVICE_OVERRIDE"
        print -r -- "$line"
        return
    fi

    if [[ -n "$EXISTING_DEVICE_ID" ]]; then
        local existing_line="$(awk -F '\t' -v id="$EXISTING_DEVICE_ID" '$1 == id {print; exit}' "$CANDIDATES")"
        if [[ -n "$existing_line" ]]; then
            print -r -- "$existing_line"
            return
        fi
    fi

    if (( count == 1 )); then
        head -n 1 "$CANDIDATES"
        return
    fi

    log "Plusieurs appareils iOS sont disponibles :"
    local i=1
    while IFS=$'\t' read -r id udid name os pairing tunnel; do
        print -r -- "  $i) $name — iOS ${os:-?} — ${tunnel:-état inconnu}"
        (( i++ ))
    done < "$CANDIDATES"

    local choice
    while true; do
        print -n -r -- "Choix [1-$count] : "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
            sed -n "${choice}p" "$CANDIDATES"
            return
        fi
        print -u2 -r -- "Choix invalide."
    done
}

DEVICE_LINE="$(select_device)"
IFS=$'\t' read -r DEVICE_ID XCODE_DEVICE_UDID DEVICE_NAME DEVICE_OS DEVICE_PAIRING DEVICE_TUNNEL <<< "$DEVICE_LINE"

log "Appareil      : $DEVICE_NAME"
log "CoreDevice ID : $DEVICE_ID"

if ! xcrun devicectl device info details --device "$DEVICE_ID" >/dev/null 2>&1; then
    die "L'appareil '$DEVICE_NAME' est connu mais n'est pas actuellement joignable."
fi

if [[ -z "$XCODE_DEVICE_UDID" ]]; then
    log "Recherche de l'UDID Xcode…"
    DESTINATIONS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>&1 || true)"
    XCODE_DEVICE_UDID="$(
        print -r -- "$DESTINATIONS" |
        grep -F "name:$DEVICE_NAME" |
        grep -F "platform:iOS" |
        head -n 1 |
        sed -E 's/.*id:([^,}]+).*/\1/' |
        xargs
    )"
fi

[[ -n "$XCODE_DEVICE_UDID" ]] || die "Impossible de déterminer l'UDID Xcode de '$DEVICE_NAME'."
log "Xcode UDID    : $XCODE_DEVICE_UDID"

security find-identity -v -p codesigning 2>/dev/null |
    grep '"Apple Development:' |
    grep -v 'CSSMERR_' |
    sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+([0-9A-Fa-f]{40})[[:space:]]+"([^"]+)".*/\1\t\2/' \
    > "$IDENTITIES" || true

CERT_COUNT="$(grep -c '.' "$IDENTITIES" || true)"
(( CERT_COUNT > 0 )) || die "Aucun certificat Apple Development valide trouvé."

normalize_sha1() {
    print -r -- "$1" | tr -d '[:space:]:' | tr '[:lower:]' '[:upper:]'
}

if [[ -n "$CERT_OVERRIDE" ]]; then
    CERT_OVERRIDE="$(normalize_sha1 "$CERT_OVERRIDE")"
    CERT_LINE="$(awk -F '\t' -v sha="$CERT_OVERRIDE" 'toupper($1) == sha {print; exit}' "$IDENTITIES")"
    [[ -n "$CERT_LINE" ]] || die "Certificat demandé invalide ou absent : $CERT_OVERRIDE"
else
    # Réutiliser prioritairement le certificat déjà épinglé.
    EXISTING_CERT_SHA1="$(normalize_sha1 "$EXISTING_CERT_SHA1")"
    CERT_LINE=""

    if [[ -n "$EXISTING_CERT_SHA1" ]]; then
        CERT_LINE="$(awk -F '\t' -v sha="$EXISTING_CERT_SHA1" 'toupper($1) == sha {print; exit}' "$IDENTITIES")"
    fi

    if [[ -z "$CERT_LINE" ]]; then
        if (( CERT_COUNT == 1 )); then
            CERT_LINE="$(head -n 1 "$IDENTITIES")"
        else
            log "Plusieurs certificats Apple Development valides sont disponibles :"
            i=1
            while IFS=$'\t' read -r sha name; do
                print -r -- "  $i) $name"
                print -r -- "     $sha"
                (( i++ ))
            done < "$IDENTITIES"

            while true; do
                print -n -r -- "Choix [1-$CERT_COUNT] : "
                read -r choice
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= CERT_COUNT )); then
                    CERT_LINE="$(sed -n "${choice}p" "$IDENTITIES")"
                    break
                fi
                print -u2 -r -- "Choix invalide."
            done
        fi

        # Si un certificat était déjà épinglé et qu'il n'est plus disponible,
        # ne jamais adopter silencieusement le nouveau.
        if [[ -n "$EXISTING_CERT_SHA1" ]]; then
            NEW_SHA="$(print -r -- "$CERT_LINE" | awk -F '\t' '{print toupper($1)}')"
            if [[ "$NEW_SHA" != "$EXISTING_CERT_SHA1" ]] && (( ! ACCEPT_NEW_CERT )); then
                print
                print -u2 -r -- "ATTENTION : le certificat Apple Development épinglé a changé."
                print -u2 -r -- "Ancien : $EXISTING_CERT_SHA1"
                print -u2 -r -- "Nouveau : $NEW_SHA"
                print -n -r -- "Accepter explicitement ce nouveau certificat ? [y/N] "
                read -r answer
                case "$answer" in
                    y|Y|yes|YES|oui|OUI) ;;
                    *) die "Nouveau certificat non accepté. Aucune configuration n'a été modifiée." ;;
                esac
            fi
        fi
    fi
fi

IFS=$'\t' read -r EXPECTED_SIGNING_CERT_SHA1 CERT_NAME <<< "$CERT_LINE"
EXPECTED_SIGNING_CERT_SHA1="$(normalize_sha1 "$EXPECTED_SIGNING_CERT_SHA1")"

log "Certificat : $CERT_NAME"
log "SHA-1      : $EXPECTED_SIGNING_CERT_SHA1"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
backup_if_exists "$CONFIG_FILE"

cat > "$CONFIG_FILE" <<EOF
# Généré automatiquement par Tools/install-renew-ios.sh v${INSTALLER_VERSION}
# $(date '+%Y-%m-%d %H:%M:%S %Z')
# Ne pas versionner ce fichier.

DEVICE_ID="$DEVICE_ID"
XCODE_DEVICE_UDID="$XCODE_DEVICE_UDID"
EXPECTED_SIGNING_CERT_SHA1="$EXPECTED_SIGNING_CERT_SHA1"

# Paramètres optionnels :
# RENEW_WINDOW_HOURS=12
# MIN_FRESH_VALIDITY_HOURS=120
# RETRY_AFTER_SECONDS=1800
EOF

chmod 600 "$CONFIG_FILE"
log "Configuration générée : $CONFIG_FILE"

mkdir -p "$LAUNCHAGENT_DIR"
launchctl bootout "gui/$(id -u)" "$PLIST_FILE" >/dev/null 2>&1 || true
backup_if_exists "$PLIST_FILE"

RENEW_SCRIPT_XML="$(
    print -r -- "$RENEW_SCRIPT" |
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
)"

cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LAUNCHD_LABEL}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>${RENEW_SCRIPT_XML}</string>
    </array>

    <key>StartInterval</key>
    <integer>${INTERVAL_SECONDS}</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/lettres-et-scores-renew.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/lettres-et-scores-renew-error.log</string>
</dict>
</plist>
EOF

plutil -lint "$PLIST_FILE" >/dev/null || die "Le plist généré est invalide."
log "LaunchAgent généré : $PLIST_FILE"

launchctl bootstrap "gui/$(id -u)" "$PLIST_FILE" \
    || die "Impossible de charger le LaunchAgent."

log "LaunchAgent activé."

if (( RUN_TEST )); then
    log "Premier test de renouvellement…"
    "$RENEW_SCRIPT" --force
else
    log "Premier test ignoré (--no-test)."
fi

print
log "Installation terminée."
log "État          : $RENEW_SCRIPT --status"
log "Journal       : /tmp/lettres-et-scores-renew.log"
log "Erreurs       : /tmp/lettres-et-scores-renew-error.log"
log "Désinstallation : $0 --uninstall"
