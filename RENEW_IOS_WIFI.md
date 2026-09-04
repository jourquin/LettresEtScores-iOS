# Renouvellement automatique du certificat de Lettres & Scores sur iPhone par Wi‑Fi

Ce document décrit la procédure complète pour reconstruire, re-signer et réinstaller automatiquement **Lettres & Scores** sur un iPhone lorsqu'il est installé avec un compte développeur Apple personnel (*Personal Team*).

L'objectif est d'éviter d'ouvrir Xcode et de relancer manuellement l'application chaque semaine.

La solution repose sur :

- `xcodebuild` pour compiler et signer l'application ;
- `devicectl` pour vérifier l'iPhone et installer l'application ;
- un contrôle du **Developer Disk Image (DDI)** ;
- un contrôle du certificat réellement utilisé pour signer l'application ;
- un **LaunchAgent macOS** pour automatiser les tentatives de renouvellement ;
- une connexion Wi‑Fi entre le Mac et l'iPhone après la préparation initiale.

> Avec une *Personal Team*, le profil de provisioning reste de courte durée (7 jours). Cette procédure automatise son renouvellement autant que possible, mais ne contourne pas les limitations imposées par Apple.


## 1. Fichiers utilisés

Le dépôt contient les fichiers suivants :

```text
LettresEtScores-iOS/
├── RENEW_IOS_WIFI.md
└── Tools/
    ├── renew-ios-wifi.sh
    ├── renew-ios.conf.example
    └── be.bartjourquin.lettresetcores.renew-ios.plist.example
```

Le fichier de configuration réel restee **hors du dépôt** :

```text
~/.config/lettres-et-scores/renew-ios.conf
```

Il contient notamment les identifiants propres à l'iPhone et l'empreinte du certificat de signature.


# 2. Prérequis

Il faut disposer de :

- macOS ;
- Xcode installé ;
- le compte Apple configuré dans Xcode ;
- le projet `LettresEtScores.xcodeproj` ;
- le scheme `LettresEtScores` ;
- **Automatic Signing** activé ;
- le mode développeur activé sur l'iPhone ;
- l'iPhone appairé avec le Mac ;
- le support de la version d'iOS de l'iPhone installé dans Xcode.

Vérifier Xcode :

```bash
xcodebuild -version
```

Vérifier `devicectl` :

```bash
xcrun devicectl help
```

Si plusieurs versions de Xcode sont installées, sélectionner celle à utiliser :

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```


# 3. Préparation initiale de l'iPhone

La toute première préparation doit idéalement être effectuée avec l'iPhone **branché physiquement au Mac**.

1. Brancher l'iPhone au Mac.
2. Déverrouiller l'iPhone.
3. Accepter la relation de confiance si elle est demandée.
4. Ouvrir Xcode.
5. Aller dans :

```text
Window → Devices and Simulators
```

ou, selon la version de Xcode :

```text
Window → Device Hub
```

6. Sélectionner l'iPhone.
7. Attendre que Xcode termine la préparation de l'appareil.
8. Vérifier que **Developer Mode** est activé sur l'iPhone.
9. Sélectionner l'iPhone comme destination d'exécution du projet.
10. Lancer **Lettres & Scores** une fois depuis Xcode.

Une fois cette préparation terminée, le câble peut normalement être débranché.

Les renouvellements suivants peuvent alors être effectués par Wi‑Fi.


# 4. Vérifier que l'iPhone est joignable par Wi‑Fi

Débrancher le câble puis exécuter :

```bash
xcrun devicectl list devices
```

Repérer l'iPhone.

Tester ensuite l'accès CoreDevice :

```bash
xcrun devicectl device info details \
  --device VOTRE_DEVICE_ID
```

Si cette commande fonctionne sans câble, le Mac voit bien l'iPhone via le réseau.


# 5. Deux identifiants peuvent être nécessaires

Selon la version de Xcode, `devicectl` et `xcodebuild` peuvent utiliser deux identifiants différents pour le même iPhone.

Le script distingue donc :

```text
DEVICE_ID
```

utilisé par `devicectl`, et :

```text
XCODE_DEVICE_UDID
```

utilisé par `xcodebuild`.

## Identifiant CoreDevice

Lister les appareils :

```bash
xcrun devicectl list devices
```

L'identifiant utilisé par `devicectl` est à placer dans :

```bash
DEVICE_ID="..."
```

## UDID utilisé par Xcode

Depuis la racine du dépôt :

```bash
xcodebuild \
  -project LettresEtScores.xcodeproj \
  -scheme LettresEtScores \
  -showdestinations
```

Repérer la ligne de l'iPhone.

Exemple :

```text
{ platform:iOS, arch:arm64, id:00008130-XXXXXXXXXXXX, name:iPhone }
```

La valeur de `id:` correspond à :

```bash
XCODE_DEVICE_UDID="..."
```


# 6. Vérifier le Developer Disk Image

Le fait que `devicectl device info details` fonctionne ne suffit pas toujours à garantir que l'iPhone est prêt comme destination de développement Xcode.

Tester explicitement les services DDI :

```bash
xcrun devicectl device info ddiServices \
  --device VOTRE_DEVICE_ID
```

Cette commande doit fonctionner.

Pour afficher l'image DDI préférée par Xcode :

```bash
xcrun devicectl list preferredDDI
```

## Si le DDI ne peut pas être monté

Un message du type :

```text
The developer disk image could not be mounted on this device
```

signifie que l'iPhone est visible, mais pas encore prêt comme destination de développement.

Procédure :

1. rebrancher temporairement l'iPhone ;
2. le déverrouiller ;
3. ouvrir Xcode ;
4. ouvrir `Devices and Simulators` / `Device Hub` ;
5. sélectionner l'iPhone ;
6. attendre la fin de la préparation ;
7. vérifier Developer Mode ;
8. vérifier que la version de Xcode prend en charge la version d'iOS installée ;
9. lancer Lettres & Scores une fois depuis Xcode ;
10. retester :

```bash
xcrun devicectl device info ddiServices \
  --device VOTRE_DEVICE_ID
```

Après certaines mises à jour d'iOS ou de Xcode, cette préparation peut devoir être répétée.


# 7. Identifier le certificat Apple Development à conserver

Le script v3.1.2 vérifie que l'application est toujours signée avec le même certificat.

Lister les identités de signature :

```bash
security find-identity -v -p codesigning
```

Exemple :

```text
1) ABCDEF0123456789ABCDEF0123456789ABCDEF01 \
   "Apple Development: example@example.com (XXXXXXXXXX)"
```

L'empreinte SHA‑1 à conserver est :

```text
ABCDEF0123456789ABCDEF0123456789ABCDEF01
```

Les certificats accompagnés de :

```text
(CSSMERR_TP_CERT_REVOKED)
```

sont révoqués et ne doivent pas être utilisés.

Le script vérifiera que l'empreinte attendue existe toujours parmi les identités valides avant de lancer le build.


# 8. Installer le script

Depuis la racine du dépôt :

```bash
chmod +x Tools/renew-ios-wifi.sh
```

Vérifier la version :

```bash
Tools/renew-ios-wifi.sh --version
```

La version attendue est :

```text
3.1.2
```

Au lancement, le script affiche également :

```text
[LettresEtScores] renew-ios-wifi.sh v3.1.2
```

Cela permet d'éviter toute ambiguïté avec une ancienne version du script.


# 9. Créer la configuration locale

Créer le répertoire :

```bash
mkdir -p ~/.config/lettres-et-scores
```

Copier le modèle :

```bash
cp Tools/renew-ios.conf.example \
   ~/.config/lettres-et-scores/renew-ios.conf
```

Éditer :

```bash
nano ~/.config/lettres-et-scores/renew-ios.conf
```

Exemple de configuration :

```bash
DEVICE_ID="VOTRE_COREDEVICE_ID"

XCODE_DEVICE_UDID="VOTRE_XCODE_UDID"

EXPECTED_SIGNING_CERT_SHA1="VOTRE_EMPREINTE_SHA1"
```

Exemple complet :

```bash
DEVICE_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
XCODE_DEVICE_UDID="00008130-XXXXXXXXXXXXXXXX"
EXPECTED_SIGNING_CERT_SHA1="ABCDEF0123456789ABCDEF0123456789ABCDEF01"
```

Le fichier peut également contenir des valeurs optionnelles :

```bash
# PROJECT="$HOME/git/LettresEtScores-iOS/LettresEtScores.xcodeproj"
# SCHEME="LettresEtScores"
# CONFIGURATION="Debug"
# APP_NAME="LettresEtScores.app"

# Commencer les tentatives 12 h avant l'expiration.
# RENEW_WINDOW_HOURS=12

# Un profil doit disposer d'au moins 120 h de validité pour être
# considéré comme réellement renouvelé.
# MIN_FRESH_VALIDITY_HOURS=120

# Délai entre deux tentatives lorsque Xcode réutilise encore
# l'ancien profil.
# RETRY_AFTER_SECONDS=1800
```

> Ne pas pousser `~/.config/lettres-et-scores/renew-ios.conf` sur GitHub.


# 10. Premier test manuel

Avec l'iPhone déverrouillé et accessible par Wi‑Fi :

```bash
Tools/renew-ios-wifi.sh --force
```

Le script effectue successivement les opérations suivantes.

## 10.1 Vérification du certificat attendu

Le script vérifie que :

```bash
EXPECTED_SIGNING_CERT_SHA1
```

correspond toujours à une identité valide dans le trousseau.

Exemple :

```text
[LettresEtScores] Vérification du certificat Apple Development attendu…
[LettresEtScores] Certificat attendu présent et valide.
```

## 10.2 Vérification de l'iPhone

```text
[LettresEtScores] Vérification de l'iPhone via CoreDevice…
```

Si l'iPhone n'est pas joignable :

```text
[LettresEtScores] iPhone non joignable. Aucun build ni changement effectué.
```

Le script quitte alors sans erreur et sans lancer de compilation.

## 10.3 Vérification du DDI

```text
[LettresEtScores] Vérification des services Developer Disk Image (DDI)…
```

Puis :

```text
[LettresEtScores] Services DDI disponibles.
```

Si le DDI est indisponible, le script s'arrête avant le build.

## 10.4 Recherche de la destination Xcode

Le script vérifie la destination avec :

```bash
xcodebuild \
  -project LettresEtScores.xcodeproj \
  -scheme LettresEtScores \
  -showdestinations
```

Puis utilise :

```bash
-destination "platform=iOS,id=$XCODE_DEVICE_UDID"
```

## 10.5 Compilation et signature

Le build est réalisé avec :

```bash
xcodebuild \
  -project LettresEtScores.xcodeproj \
  -scheme LettresEtScores \
  -configuration Debug \
  -destination "platform=iOS,id=$XCODE_DEVICE_UDID" \
  -derivedDataPath .renew-derived-data \
  -allowProvisioningUpdates \
  build
```

L'option :

```text
-allowProvisioningUpdates
```

permet à Xcode de gérer automatiquement le provisioning.


# 11. Vérification du certificat réellement utilisé

Après compilation, le script extrait le certificat utilisé pour signer :

```text
LettresEtScores.app
```

La commande utilisée est équivalente à :

```bash
cd /un/repertoire/temporaire

codesign \
  --display \
  --extract-certificates \
  /chemin/LettresEtScores.app
```

`codesign` crée alors :

```text
codesign0
codesign1
...
```

Le fichier :

```text
codesign0
```

correspond au certificat feuille utilisé pour signer l'application.

Le script calcule son empreinte SHA‑1 avec `openssl` et compare :

```text
Certificat attendu
```

et :

```text
Certificat utilisé
```

Exemple normal :

```text
[LettresEtScores] Certificat attendu : ABCDEF...
[LettresEtScores] Certificat utilisé  : ABCDEF...
[LettresEtScores] Certificat de signature conforme.
```

## Si le certificat change

Le script s'arrête immédiatement :

```text
ERREUR: L'identité de signature a changé.

Attendu : ...
Obtenu  : ...

L'application N'A PAS été installée sur l'iPhone.
```

Cette sécurité permet d'éviter qu'une nouvelle identité de signature soit installée silencieusement sur l'iPhone.



# 12. Message « Développeur non approuvé »

Lors de la première installation avec un nouveau certificat Apple Development, iOS peut afficher :

```text
Développeur non approuvé
```

Dans ce cas, sur l'iPhone :

```text
Réglages
→ Général
→ VPN et gestion de l'appareil
→ App développeur
→ Faire confiance
```

Le libellé exact peut varier légèrement selon la version d'iOS.

Cette approbation doit normalement rester valable tant que le même certificat Apple Development continue d'être utilisé.

C'est précisément la raison pour laquelle le script v3.1.2 vérifie l'empreinte du certificat avant chaque installation.


# 13. Vérification du profil de provisioning

Après le build, le script lit :

```text
embedded.mobileprovision
```

dans :

```text
LettresEtScores.app
```

Il extrait notamment :

- l'UUID du profil ;
- sa date d'expiration.

La simple réussite d'un build ne suffit pas toujours à prouver qu'un nouveau profil a été créé : Xcode peut parfois réutiliser un profil encore valable.

Le script vérifie donc la durée de validité restante.

Par défaut :

```text
MIN_FRESH_VALIDITY_HOURS=120
```

Un profil doit donc avoir au moins cinq jours de validité restante pour être considéré comme réellement renouvelé.

Si Xcode réutilise encore un ancien profil proche de son expiration :

```text
[LettresEtScores] Xcode a réutilisé un profil qui expire dans moins de 120 h.
[LettresEtScores] Pas de réinstallation inutile.
```

Le script planifie alors une nouvelle tentative plus tard.


# 14. Installation sur l'iPhone par Wi‑Fi

Si toutes les vérifications sont satisfaites, l'installation est effectuée avec :

```bash
xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  "/chemin/LettresEtScores.app"
```

Le script ne supprime pas volontairement l'application avant installation.

Il installe la nouvelle build utilisant le même Bundle Identifier.

Cela permet normalement de conserver les données de l'application.


# 15. Vérifier l'état du renouvellement

Exécuter :

```bash
Tools/renew-ios-wifi.sh --status
```

Exemple :

```text
[LettresEtScores] Configuration       : ...
[LettresEtScores] CoreDevice ID       : ...
[LettresEtScores] Xcode Device UDID   : ...
[LettresEtScores] Certificat attendu  : ...
[LettresEtScores] Profil UUID         : ...
[LettresEtScores] Expiration          : ...
[LettresEtScores] Prochain essai      : ...
```

Le fichier d'état est stocké dans :

```text
~/.local/state/lettres-et-scores/renew-ios.state
```


# 16. Automatisation avec launchd

Le dépôt contient un modèle :

```text
Tools/be.bartjourquin.lettresetcores.renew-ios.plist.example
```

Créer le LaunchAgent utilisateur :

```bash
cp \
  Tools/be.bartjourquin.lettresetcores.renew-ios.plist.example \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Éditer :

```bash
nano \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Modifier le chemin absolu vers le script.

Exemple :

```xml
<string>/Users/moncompte/git/LettresEtScores-iOS/Tools/renew-ios-wifi.sh</string>
```

Le chemin doit être absolu.


# 17. Vérifier le fichier plist

Exécuter :

```bash
plutil -lint \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

La sortie attendue est :

```text
OK
```


# 18. Activer le LaunchAgent

Charger l'automatisation :

```bash
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Pour provoquer immédiatement une exécution :

```bash
launchctl kickstart \
  gui/$(id -u)/be.bartjourquin.lettresetcores.renew-ios
```


# 19. Fréquence des vérifications

Le modèle de LaunchAgent utilise :

```xml
<key>StartInterval</key>
<integer>1800</integer>
```

soit :

```text
30 minutes
```

Cela ne signifie pas que l'application est recompilée toutes les 30 minutes.

Le script consulte d'abord son fichier d'état :

```text
~/.local/state/lettres-et-scores/renew-ios.state
```

Si aucune tentative n'est nécessaire, il quitte immédiatement.

La plupart des exécutions sont donc très légères.

La compilation ne commence que lorsqu'une nouvelle tentative de renouvellement est nécessaire.


# 20. Journaux de l'automatisation

Le LaunchAgent écrit ses sorties dans :

```text
/tmp/lettres-et-scores-renew.log
```

et ses erreurs dans :

```text
/tmp/lettres-et-scores-renew-error.log
```

Suivre le journal :

```bash
tail -f /tmp/lettres-et-scores-renew.log
```

Afficher les dernières erreurs :

```bash
tail -100 /tmp/lettres-et-scores-renew-error.log
```

---

# 21. Tester l'automatisation

Après activation :

```bash
launchctl kickstart \
  gui/$(id -u)/be.bartjourquin.lettresetcores.renew-ios
```

Puis :

```bash
tail -f /tmp/lettres-et-scores-renew.log
```

Le début normal ressemble à :

```text
[LettresEtScores] renew-ios-wifi.sh v3.1.2
[LettresEtScores] Vérification du certificat Apple Development attendu…
[LettresEtScores] Certificat attendu présent et valide.
```

Selon l'état du profil, le script peut ensuite :

- quitter immédiatement ;
- constater que l'iPhone est absent ;
- lancer un renouvellement ;
- refuser une installation si le certificat a changé.


# 22. Modifier le LaunchAgent

Avant toute modification importante du fichier `.plist`, le décharger :

```bash
launchctl bootout gui/$(id -u) \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Modifier le fichier.

Puis le recharger :

```bash
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```


# 23. Désactiver l'automatisation

Décharger le LaunchAgent :

```bash
launchctl bootout gui/$(id -u) \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Pour supprimer complètement l'automatisation :

```bash
rm \
  ~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

La configuration locale peut également être supprimée :

```bash
rm ~/.config/lettres-et-scores/renew-ios.conf
```

Et l'état :

```bash
rm -rf ~/.local/state/lettres-et-scores
```

Cela ne désinstalle pas Lettres & Scores de l'iPhone.


# 24. Dépannage

## L'iPhone n'est pas joignable

Tester :

```bash
xcrun devicectl device info details \
  --device VOTRE_DEVICE_ID
```

Vérifier :

- que l'iPhone est allumé ;
- qu'il est déverrouillé ;
- qu'il a déjà été appairé avec ce Mac ;
- que le Mac et l'iPhone peuvent communiquer sur le réseau.


## Le DDI ne fonctionne pas

Tester :

```bash
xcrun devicectl device info ddiServices \
  --device VOTRE_DEVICE_ID
```

Puis :

```bash
xcrun devicectl list preferredDDI
```

Si nécessaire :

- rebrancher l'iPhone ;
- ouvrir Xcode ;
- attendre la préparation dans Device Hub ;
- vérifier Developer Mode ;
- vérifier la compatibilité entre Xcode et iOS ;
- lancer l'application une fois depuis Xcode.


## `xcodebuild` ne trouve pas la destination

Lister les destinations :

```bash
xcodebuild \
  -project LettresEtScores.xcodeproj \
  -scheme LettresEtScores \
  -showdestinations
```

Vérifier la valeur :

```bash
XCODE_DEVICE_UDID
```

dans la configuration locale.


## Le certificat attendu n'est plus valide

Lister :

```bash
security find-identity -v -p codesigning
```

Si l'empreinte attendue n'apparaît plus parmi les identités valides, le script s'arrête volontairement.

Il faut alors déterminer pourquoi le certificat a changé avant de mettre à jour :

```bash
EXPECTED_SIGNING_CERT_SHA1
```


## Xcode utilise un nouveau certificat

Le script affiche :

```text
L'identité de signature a changé.
```

L'application n'est pas installée.

Avant de modifier la configuration :

1. vérifier les certificats dans Xcode ;
2. vérifier les certificats dans le trousseau ;
3. déterminer si le changement était attendu ;
4. approuver volontairement le nouveau certificat si nécessaire ;
5. mettre ensuite à jour `EXPECTED_SIGNING_CERT_SHA1`.


## Message « Développeur non approuvé »

Sur l'iPhone :

```text
Réglages
→ Général
→ VPN et gestion de l'appareil
→ App développeur
→ Faire confiance
```

Cette étape est normalement nécessaire uniquement lorsqu'un nouveau certificat de développement est utilisé.


## Le script compile mais ne réinstalle pas l'application

C'est volontaire si le profil généré n'est pas considéré comme suffisamment récent.

Afficher l'état :

```bash
Tools/renew-ios-wifi.sh --status
```

Forcer une nouvelle tentative :

```bash
Tools/renew-ios-wifi.sh --force
```


# 25. Bonnes pratiques

Il est recommandé de :

- conserver le même certificat Apple Development aussi longtemps que possible ;
- ne pas révoquer volontairement le certificat utilisé par le script ;
- ne pas supprimer l'application de l'iPhone avant un renouvellement ;
- conserver le même Bundle Identifier ;
- ne pas versionner la configuration locale ;
- laisser Xcode installé sur le Mac ;
- conserver le Mac connecté au compte Apple utilisé pour signer ;
- vérifier les journaux après une mise à jour importante d'iOS ou de Xcode.


# 26. Résumé du fonctionnement

Le cycle automatisé est le suivant :

```text
launchd
  ↓
renew-ios-wifi.sh
  ↓
vérification du certificat attendu
  ↓
vérification de l'iPhone
  ↓
vérification DDI
  ↓
vérification de la destination Xcode
  ↓
xcodebuild + Automatic Signing
  ↓
contrôle du certificat réellement utilisé
  ↓
contrôle de la date d'expiration du provisioning
  ↓
installation par Wi‑Fi avec devicectl
  ↓
enregistrement de la prochaine fenêtre de renouvellement
```

Ainsi, tant que :

- le Mac est allumé ;
- l'iPhone est accessible ;
- Xcode reste correctement configuré ;
- le certificat attendu reste valide ;

le renouvellement de Lettres & Scores peut se faire sans intervention manuelle régulière.
