#!/bin/zsh
#
# renew-ios-wifi.sh
# Renouvelle et réinstalle Lettres & Scores sur un iPhone appairé en Wi‑Fi.
#
# Version 3.1.1
#
set -euo pipefail

SCRIPT_VERSION="3.1.2"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${LETTRES_SCORES_RENEW_CONFIG:-$HOME/.config/lettres-et-scores/renew-ios.conf}"
STATE_DIR="${LETTRES_SCORES_RENEW_STATE_DIR:-$HOME/.local/state/lettres-et-scores}"
STATE_FILE="$STATE_DIR/renew-ios.state"
LOG_PREFIX="[LettresEtScores]"

PROJECT="${PROJECT:-$PROJECT_ROOT/LettresEtScores.xcodeproj}"
SCHEME="${SCHEME:-LettresEtScores}"
CONFIGURATION="${CONFIGURATION:-Debug}"
APP_NAME="${APP_NAME:-LettresEtScores.app}"
DERIVED_DATA="${DERIVED_DATA:-$PROJECT_ROOT/.renew-derived-data}"

RENEW_WINDOW_HOURS="${RENEW_WINDOW_HOURS:-12}"
MIN_FRESH_VALIDITY_HOURS="${MIN_FRESH_VALIDITY_HOURS:-120}"
RETRY_AFTER_SECONDS="${RETRY_AFTER_SECONDS:-1800}"

FORCE=0
SHOW_STATUS=0
SHOW_VERSION=0

log() {
    print -r -- "$LOG_PREFIX $*"
}

die() {
    print -u2 -r -- "$LOG_PREFIX ERREUR: $*"
    exit 1
}

usage() {
    cat <<EOF
renew-ios-wifi.sh v${SCRIPT_VERSION}

Usage:
  renew-ios-wifi.sh [--force] [--status] [--version]

Options:
  --force    Ignore la prochaine date planifiée et tente immédiatement.
  --status   Affiche l'état enregistré puis quitte.
  --version  Affiche la version du script.
  -h         Affiche cette aide.
EOF
}

normalize_sha1() {
    # Accepte une empreinte avec ou sans ":" et en minuscules/majuscules.
    print -r -- "$1" | tr -d '[:space:]:' | tr '[:lower:]' '[:upper:]'
}

while (( $# > 0 )); do
    case "$1" in
        --force) FORCE=1 ;;
        --status) SHOW_STATUS=1 ;;
        --version) SHOW_VERSION=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Option inconnue: $1" ;;
    esac
    shift
done

if (( SHOW_VERSION )); then
    print -r -- "$SCRIPT_VERSION"
    exit 0
fi

log "renew-ios-wifi.sh v${SCRIPT_VERSION}"

[[ -f "$CONFIG_FILE" ]] || die "Fichier de configuration absent: $CONFIG_FILE
Copiez Tools/renew-ios.conf.example vers cet emplacement puis renseignez DEVICE_ID."

# shellcheck disable=SC1090
source "$CONFIG_FILE"

[[ -n "${DEVICE_ID:-}" ]] || die "DEVICE_ID n'est pas défini dans $CONFIG_FILE"
[[ -n "${EXPECTED_SIGNING_CERT_SHA1:-}" ]] || die "EXPECTED_SIGNING_CERT_SHA1 n'est pas défini dans $CONFIG_FILE.

Ajoutez l'empreinte du certificat Apple Development à conserver, par exemple :
  EXPECTED_SIGNING_CERT_SHA1=\"2EFED54F866EDD1E1105CE3F675A7356DFDB1B65\""

EXPECTED_CERT_SHA1="$(normalize_sha1 "$EXPECTED_SIGNING_CERT_SHA1")"

if [[ ! "$EXPECTED_CERT_SHA1" =~ ^[0-9A-F]{40}$ ]]; then
    die "EXPECTED_SIGNING_CERT_SHA1 n'est pas une empreinte SHA-1 valide (40 caractères hexadécimaux)."
fi

mkdir -p "$STATE_DIR"

LAST_PROFILE_UUID=""
LAST_PROFILE_EXPIRY_EPOCH="0"
NEXT_ATTEMPT_EPOCH="0"

if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
fi

if (( SHOW_STATUS )); then
    log "Configuration       : $CONFIG_FILE"
    log "CoreDevice ID       : $DEVICE_ID"
    log "Xcode Device UDID   : ${XCODE_DEVICE_UDID:-détection automatique}"
    log "Certificat attendu  : $EXPECTED_CERT_SHA1"
    log "Projet              : $PROJECT"
    log "Scheme              : $SCHEME"
    if (( LAST_PROFILE_EXPIRY_EPOCH > 0 )); then
        log "Profil UUID         : ${LAST_PROFILE_UUID:-inconnu}"
        log "Expiration          : $(date -r "$LAST_PROFILE_EXPIRY_EPOCH" '+%Y-%m-%d %H:%M:%S %Z')"
        log "Prochain essai      : $(date -r "$NEXT_ATTEMPT_EPOCH" '+%Y-%m-%d %H:%M:%S %Z')"
    else
        log "Aucun renouvellement réussi n'est encore enregistré."
    fi
    exit 0
fi

NOW="$(date +%s)"

if (( ! FORCE && NEXT_ATTEMPT_EPOCH > NOW )); then
    log "Rien à faire avant $(date -r "$NEXT_ATTEMPT_EPOCH" '+%Y-%m-%d %H:%M:%S %Z')."
    exit 0
fi

command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild introuvable."
command -v xcrun >/dev/null 2>&1 || die "xcrun introuvable."
command -v security >/dev/null 2>&1 || die "security introuvable."
command -v plutil >/dev/null 2>&1 || die "plutil introuvable."
command -v codesign >/dev/null 2>&1 || die "codesign introuvable."
command -v openssl >/dev/null 2>&1 || die "openssl introuvable."

# ---------------------------------------------------------------------------
# 0) Vérifier que l'identité attendue existe toujours et est valide
# ---------------------------------------------------------------------------

log "Vérification du certificat Apple Development attendu…"

VALID_IDENTITIES="$(
    security find-identity -v -p codesigning 2>/dev/null || true
)"

if ! print -r -- "$VALID_IDENTITIES" | grep -Fq "$EXPECTED_CERT_SHA1"; then
    print -u2 -r -- "$VALID_IDENTITIES"
    die "Le certificat attendu $EXPECTED_CERT_SHA1 n'apparaît pas parmi les identités de signature valides du trousseau.

L'installation est annulée afin d'éviter que Xcode crée/utilise silencieusement
une autre identité et provoque une nouvelle demande « Développeur non approuvé »."
fi

log "Certificat attendu présent et valide."

# ---------------------------------------------------------------------------
# 1) Présence réseau/CoreDevice
# ---------------------------------------------------------------------------

log "Vérification de l'iPhone via CoreDevice…"
if ! xcrun devicectl device info details --device "$DEVICE_ID" >/dev/null 2>&1; then
    log "iPhone non joignable. Aucun build ni changement effectué."
    exit 0
fi

# ---------------------------------------------------------------------------
# 2) Préflight DDI
# ---------------------------------------------------------------------------

log "Vérification des services Developer Disk Image (DDI)…"

DDI_LOG="$(mktemp -t lettres-et-scores-ddi)"
CERT_DIR="$(mktemp -d -t lettres-et-scores-cert)"
TMP_PLIST=""

cleanup() {
    rm -f "$DDI_LOG"
    [[ -n "$TMP_PLIST" ]] && rm -f "$TMP_PLIST"
    rm -rf "$CERT_DIR"
}
trap cleanup EXIT

set +e
xcrun devicectl device info ddiServices \
    --device "$DEVICE_ID" >"$DDI_LOG" 2>&1
DDI_STATUS=$?
set -e

if (( DDI_STATUS != 0 )); then
    print -u2 -r -- ""
    print -u2 -r -- "----- diagnostic devicectl ddiServices -----"
    cat "$DDI_LOG" >&2
    print -u2 -r -- "---------------------------------------------"

    print -u2 -r -- ""
    print -u2 -r -- "----- diagnostic devicectl preferredDDI -----"
    xcrun devicectl list preferredDDI >&2 2>&1 || true
    print -u2 -r -- "----------------------------------------------"

    die "Le Developer Disk Image n'est pas disponible sur l'iPhone."
fi

log "Services DDI disponibles."

# ---------------------------------------------------------------------------
# 3) Destination xcodebuild
# ---------------------------------------------------------------------------

log "Recherche de la destination Xcode…"

DESTINATIONS="$(xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -showdestinations 2>&1 || true)"

if [[ -n "${XCODE_DEVICE_UDID:-}" ]]; then
    XCODE_UDID="$XCODE_DEVICE_UDID"
else
    PHYSICAL_LINES="$(
        print -r -- "$DESTINATIONS" |
        grep -E '^[[:space:]]*\{ platform:iOS,' |
        grep -v 'DVTiPhonePlaceholder' || true
    )"

    PHYSICAL_COUNT="$(
        print -r -- "$PHYSICAL_LINES" |
        grep -c 'id:' || true
    )"

    if [[ "$PHYSICAL_COUNT" == "1" ]]; then
        XCODE_UDID="$(
            print -r -- "$PHYSICAL_LINES" |
            sed -E 's/.*id:([^,}]+).*/\1/' |
            xargs
        )"
        log "UDID Xcode détecté automatiquement : $XCODE_UDID"
    else
        print -u2 -r -- "$DESTINATIONS"
        die "Impossible de déterminer automatiquement l'UDID Xcode.
Ajoutez XCODE_DEVICE_UDID=\"...\" dans $CONFIG_FILE."
    fi
fi

DEST_LINE="$(
    print -r -- "$DESTINATIONS" |
    grep -F "id:$XCODE_UDID" |
    head -n 1 || true
)"

if [[ -z "$DEST_LINE" ]]; then
    print -u2 -r -- "$DESTINATIONS"
    die "L'UDID $XCODE_UDID n'apparaît pas parmi les destinations Xcode."
fi

if [[ "$DEST_LINE" == *"error:"* ]]; then
    print -u2 -r -- "$DEST_LINE"
    die "La destination Xcode existe mais n'est pas disponible."
fi

APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/$APP_NAME"

# ---------------------------------------------------------------------------
# 4) Build + Automatic Signing
# ---------------------------------------------------------------------------

log "Destination Xcode prête : $XCODE_UDID"
log "Compilation/signature avec Automatic Signing…"

set +e
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=iOS,id=$XCODE_UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    -allowProvisioningUpdates \
    build
BUILD_STATUS=$?
set -e

if (( BUILD_STATUS != 0 )); then
    die "La compilation/signature a échoué (code $BUILD_STATUS)."
fi

[[ -d "$APP_PATH" ]] || die "Application compilée introuvable: $APP_PATH"
[[ -f "$APP_PATH/embedded.mobileprovision" ]] || die "Profil embedded.mobileprovision introuvable dans l'application."

# ---------------------------------------------------------------------------
# 5) PINNING : vérifier le certificat réellement utilisé pour signer l'app
# ---------------------------------------------------------------------------

log "Vérification du certificat réellement utilisé pour signer l'application…"

# `codesign --extract-certificates` écrit codesign0, codesign1, ...
# dans le répertoire courant. On exécute donc la commande depuis un
# répertoire temporaire dédié, comme recommandé dans la documentation Apple.
set +e
(
    cd "$CERT_DIR" || exit 1
    codesign --display --extract-certificates "$APP_PATH" >/dev/null 2>&1
)
CERT_EXTRACT_STATUS=$?
set -e

CERT_FILE="$CERT_DIR/codesign0"

if (( CERT_EXTRACT_STATUS != 0 )) || [[ ! -f "$CERT_FILE" ]]; then
    print -u2 -r -- ""
    print -u2 -r -- "Diagnostic codesign :"
    codesign --display -vv "$APP_PATH" >&2 2>&1 || true
    die "Impossible d'extraire le certificat de signature de $APP_PATH."
fi

ACTUAL_CERT_SHA1="$(
    openssl x509 \
        -inform DER \
        -in "$CERT_FILE" \
        -noout \
        -fingerprint \
        -sha1 2>/dev/null |
    sed -E 's/^[^=]+=//' |
    tr -d ':' |
    tr '[:lower:]' '[:upper:]'
)"

if [[ ! "$ACTUAL_CERT_SHA1" =~ ^[0-9A-F]{40}$ ]]; then
    die "Impossible de calculer l'empreinte SHA-1 du certificat utilisé pour signer l'application."
fi

log "Certificat attendu : $EXPECTED_CERT_SHA1"
log "Certificat utilisé  : $ACTUAL_CERT_SHA1"

if [[ "$ACTUAL_CERT_SHA1" != "$EXPECTED_CERT_SHA1" ]]; then
    die "L'identité de signature a changé.

Attendu : $EXPECTED_CERT_SHA1
Obtenu  : $ACTUAL_CERT_SHA1

L'application N'A PAS été installée sur l'iPhone.
Cette protection évite d'introduire silencieusement un nouveau certificat qui
pourrait déclencher une nouvelle demande « Développeur non approuvé »."
fi

log "Certificat de signature conforme."

# ---------------------------------------------------------------------------
# 6) Vérification de la fraîcheur du provisioning
# ---------------------------------------------------------------------------

TMP_PLIST="$(mktemp -t lettres-et-scores-profile).plist"
security cms -D -i "$APP_PATH/embedded.mobileprovision" > "$TMP_PLIST"

PROFILE_UUID="$(plutil -extract UUID raw -o - "$TMP_PLIST")"
EXPIRATION_RAW="$(plutil -extract ExpirationDate raw -o - "$TMP_PLIST")"

date_to_epoch() {
    local value="$1"
    local epoch=""

    epoch="$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$value" "+%s" 2>/dev/null)" && {
        print -r -- "$epoch"
        return 0
    }

    epoch="$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$value" "+%s" 2>/dev/null)" && {
        print -r -- "$epoch"
        return 0
    }

    epoch="$(date -j -u -f "%Y-%m-%dT%H:%M:%S%z" "$value" "+%s" 2>/dev/null)" && {
        print -r -- "$epoch"
        return 0
    }

    return 1
}

PROFILE_EXPIRY_EPOCH="$(date_to_epoch "$EXPIRATION_RAW")" || \
    die "Impossible d'interpréter ExpirationDate: $EXPIRATION_RAW"

NOW="$(date +%s)"
REMAINING_SECONDS=$(( PROFILE_EXPIRY_EPOCH - NOW ))
MIN_FRESH_SECONDS=$(( MIN_FRESH_VALIDITY_HOURS * 3600 ))

log "Profil obtenu : $PROFILE_UUID"
log "Expiration    : $(date -r "$PROFILE_EXPIRY_EPOCH" '+%Y-%m-%d %H:%M:%S %Z')"

if (( REMAINING_SECONDS < MIN_FRESH_SECONDS )); then
    NEXT_ATTEMPT_EPOCH=$(( NOW + RETRY_AFTER_SECONDS ))
    cat > "$STATE_FILE" <<EOF
LAST_PROFILE_UUID="${LAST_PROFILE_UUID}"
LAST_PROFILE_EXPIRY_EPOCH="${LAST_PROFILE_EXPIRY_EPOCH}"
NEXT_ATTEMPT_EPOCH="${NEXT_ATTEMPT_EPOCH}"
EOF
    log "Xcode a réutilisé un profil qui expire dans moins de ${MIN_FRESH_VALIDITY_HOURS} h."
    log "Pas de réinstallation inutile; nouvel essai après $(date -r "$NEXT_ATTEMPT_EPOCH" '+%Y-%m-%d %H:%M:%S %Z')."
    exit 0
fi

# ---------------------------------------------------------------------------
# 7) Installation Wi-Fi
# ---------------------------------------------------------------------------

log "Installation par Wi-Fi sur l'iPhone…"
xcrun devicectl device install app \
    --device "$DEVICE_ID" \
    "$APP_PATH"

NEXT_ATTEMPT_EPOCH=$(( PROFILE_EXPIRY_EPOCH - RENEW_WINDOW_HOURS * 3600 ))

cat > "$STATE_FILE" <<EOF
LAST_PROFILE_UUID="${PROFILE_UUID}"
LAST_PROFILE_EXPIRY_EPOCH="${PROFILE_EXPIRY_EPOCH}"
NEXT_ATTEMPT_EPOCH="${NEXT_ATTEMPT_EPOCH}"
EOF

log "Renouvellement installé avec succès."
log "Prochaine fenêtre de renouvellement: $(date -r "$NEXT_ATTEMPT_EPOCH" '+%Y-%m-%d %H:%M:%S %Z')."
