# Renouvellement automatique de Lettres & Scores sur iPhone par Wi‑Fi

Ce document décrit une méthode **expérimentale** pour reconstruire, re-signer et réinstaller automatiquement **Lettres & Scores** sur un iPhone lorsqu'il est installé avec un compte développeur Apple personnel (*Personal Team*).

L'objectif est d'éviter d'ouvrir Xcode et de relancer manuellement l'application à chaque expiration du profil de provisioning.

La solution utilise :

- `xcodebuild` pour compiler et signer l'application ;
- `devicectl` pour détecter l'iPhone, vérifier les services de développement et installer l'application ;
- un contrôle du **Developer Disk Image (DDI)** ;
- un contrôle de l'identité Apple Development réellement utilisée pour signer l'application ;
- un **LaunchAgent macOS** pour effectuer automatiquement les tentatives de renouvellement ;
- une connexion Wi‑Fi entre le Mac et l'iPhone après la préparation initiale.

> [!WARNING]
> Cette méthode est exploratoire. Elle a été développée et testée sur une configuration particulière, mais sa robustesse n'a pas été démontrée sur l'ensemble des versions de macOS, Xcode et iOS ni sur tous les types de comptes et d'appareils. Apple peut modifier le fonctionnement du provisioning, de la signature ou des outils en ligne de commande. Cette procédure ne constitue donc pas un mécanisme officiel ou garanti de renouvellement.

Avec une *Personal Team*, la durée de validité du profil de provisioning est limitée à 7 jours. Cette procédure automatise son renouvellement autant que possible mais ne contourne aucune limitation imposée par Apple.


## 1. Fichiers du dépôt

La procédure repose sur deux scripts :

```text
LettresEtScores-iOS/
├── RENEW_IOS_WIFI.md
└── Tools/
    ├── install-renew-ios.sh
    └── renew-ios-wifi.sh
```

`install-renew-ios.sh` installe et configure la procédure.

`renew-ios-wifi.sh` effectue ensuite les renouvellements.

Les fichiers de configuration sont générés automatiquement par l'installateur aux emplacements suivants :

```text
~/.config/lettres-et-scores/renew-ios.conf
~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Le fichier d'état utilisé par le script est stocké dans :

```text
~/.local/state/lettres-et-scores/renew-ios.state
```


## 2. Prérequis

Il faut disposer de :

- macOS ;
- Xcode installé ;
- un compte Apple configuré dans Xcode ;
- **Automatic Signing** activé pour la cible `LettresEtScores` ;
- le mode développeur activé sur l'iPhone ;
- l'iPhone appairé avec le Mac ;
- une version de Xcode compatible avec la version d'iOS installée sur l'iPhone.

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



## 3. Préparation initiale de l'iPhone

La première préparation doit idéalement être effectuée avec l'iPhone **branché physiquement au Mac**.

1. Brancher l'iPhone au Mac.
2. Déverrouiller l'iPhone.
3. Accepter la relation de confiance si elle est demandée.
4. Ouvrir Xcode.
5. Ouvrir **Window → Devices and Simulators** ou **Device Hub**, selon la version de Xcode.
6. Sélectionner l'iPhone.
7. Attendre que Xcode termine la préparation de l'appareil.
8. Vérifier que **Developer Mode** est activé sur l'iPhone.
9. Sélectionner l'iPhone comme destination d'exécution de `LettresEtScores`.
10. Lancer l'application une fois avec Xcode.

Une fois cette préparation terminée, le câble peut normalement être débranché.

Les renouvellements suivants peuvent alors être réalisés par Wi‑Fi.



# Installation

## 4. Lancer l'installateur

Depuis la racine du dépôt :

```bash
chmod +x Tools/install-renew-ios.sh
chmod +x Tools/renew-ios-wifi.sh
```

Puis :

```bash
Tools/install-renew-ios.sh
```

Dans le cas courant où un seul iPhone et un seul certificat Apple Development valide sont disponibles, aucune édition manuelle de fichier n'est nécessaire.

L'installateur :

1. localise automatiquement le dépôt ;
2. vérifie la présence de Xcode et des outils nécessaires ;
3. détecte les appareils iOS physiques connus de CoreDevice ;
4. détermine l'identifiant utilisé par `devicectl` ;
5. détermine l'UDID utilisé comme destination par `xcodebuild` ;
6. détecte les certificats Apple Development valides ;
7. génère le fichier `renew-ios.conf` ;
8. génère le LaunchAgent macOS ;
9. sauvegarde les éventuels fichiers existants avant de les remplacer ;
10. valide le fichier `.plist` ;
11. charge le LaunchAgent ;
12. lance un premier renouvellement avec `renew-ios-wifi.sh --force`.

Si plusieurs iPhone ou plusieurs certificats valides sont détectés, l'installateur affiche un menu numéroté.



## 5. Fichiers générés

### Configuration

L'installateur crée :

```text
~/.config/lettres-et-scores/renew-ios.conf
```

avec des permissions restreintes à l'utilisateur.

Le contenu ressemble à :

```bash
DEVICE_ID="..."
XCODE_DEVICE_UDID="..."
EXPECTED_SIGNING_CERT_SHA1="..."
```

Ces valeurs sont déterminées automatiquement.

Le fichier contient :

- `DEVICE_ID` : identifiant CoreDevice utilisé par `devicectl` ;
- `XCODE_DEVICE_UDID` : identifiant de destination utilisé par `xcodebuild` ;
- `EXPECTED_SIGNING_CERT_SHA1` : empreinte du certificat Apple Development autorisé à signer l'application.

Il ne contient aucun mot de passe Apple.

### LaunchAgent

L'installateur crée :

```text
~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Le chemin absolu vers `renew-ios-wifi.sh` est inséré automatiquement.

Le LaunchAgent exécute périodiquement le script de renouvellement.

Par défaut :

```text
StartInterval = 1800 secondes
```

soit une vérification toutes les 30 minutes.

Cela ne signifie pas que l'application est recompilée toutes les 30 minutes : `renew-ios-wifi.sh` utilise son fichier d'état pour quitter immédiatement lorsqu'aucune tentative n'est nécessaire.


## 6. Vérifier l'installation

Afficher la version de l'installateur :

```bash
Tools/install-renew-ios.sh --version
```

Afficher la version du script de renouvellement :

```bash
Tools/renew-ios-wifi.sh --version
```

Afficher son état :

```bash
Tools/renew-ios-wifi.sh --status
```

Afficher le LaunchAgent chargé :

```bash
launchctl print \
  gui/$(id -u)/be.bartjourquin.lettresetcores.renew-ios
```


## 7. Options de l'installateur

Afficher l'aide :

```bash
Tools/install-renew-ios.sh --help
```

### Installer sans effectuer immédiatement le premier test

```bash
Tools/install-renew-ios.sh --no-test
```

### Imposer un appareil précis

```bash
Tools/install-renew-ios.sh \
  --device VOTRE_COREDEVICE_ID
```

### Imposer un certificat précis

```bash
Tools/install-renew-ios.sh \
  --cert EMPREINTE_SHA1
```

### Accepter explicitement un nouveau certificat sans question interactive

```bash
Tools/install-renew-ios.sh --accept-new-cert
```

Cette option est destinée aux cas où le changement de certificat a déjà été vérifié et accepté par l'utilisateur.

### Désinstaller la configuration automatique

```bash
Tools/install-renew-ios.sh --uninstall
```

Cette commande :

- décharge le LaunchAgent ;
- supprime le `.plist` généré ;
- supprime la configuration locale.

Le fichier d'état est conservé par défaut.


# Quelques détails techniques du fonctionnement

## 8. Deux identifiants pour le même iPhone

Selon la version de Xcode, `devicectl` et `xcodebuild` peuvent utiliser deux identifiants différents pour le même appareil.

Le script distingue donc :

```text
DEVICE_ID
```

pour `devicectl`, et :

```text
XCODE_DEVICE_UDID
```

pour `xcodebuild`.

L'installateur tente de déterminer automatiquement les deux.

Pour diagnostic manuel :

```bash
xcrun devicectl list devices
```

et :

```bash
xcodebuild \
  -project LettresEtScores.xcodeproj \
  -scheme LettresEtScores \
  -showdestinations
```


## 9. Vérification du Developer Disk Image

Le fait que l'iPhone soit visible par CoreDevice ne suffit pas toujours pour qu'il soit utilisable comme destination Xcode.

Le script teste les services DDI avec :

```bash
xcrun devicectl device info ddiServices \
  --device "$DEVICE_ID"
```

Si ce test échoue, le build n'est pas lancé.

Pour diagnostiquer manuellement :

```bash
xcrun devicectl list preferredDDI
```

### Si le DDI ne peut pas être monté

Un message du type :

```text
The developer disk image could not be mounted on this device
```

indique que l'iPhone est visible mais que ses services de développement ne sont pas prêts.

Dans ce cas :

1. rebrancher temporairement l'iPhone ;
2. le déverrouiller ;
3. ouvrir Xcode ;
4. ouvrir **Devices and Simulators** / **Device Hub** ;
5. sélectionner l'iPhone ;
6. attendre la fin de la préparation ;
7. vérifier Developer Mode ;
8. vérifier la compatibilité de Xcode avec la version d'iOS ;
9. lancer `LettresEtScores` une fois depuis Xcode ;
10. relancer l'installateur ou le script.

Après une mise à jour importante d'iOS ou de Xcode, cette préparation peut devoir être répétée.



## 10. Compilation et provisioning

Lorsque le renouvellement est nécessaire, le script utilise notamment :

```bash
xcodebuild \
  -project LettresEtScores.xcodeproj \
  -scheme LettresEtScores \
  -configuration Debug \
  -destination "platform=iOS,id=$XCODE_DEVICE_UDID" \
  -allowProvisioningUpdates \
  build
```

`-allowProvisioningUpdates` permet à Xcode de gérer le provisioning via la signature automatique.


## 11. Vérification du certificat de signature

Le script ne se contente pas de vérifier que le build a réussi.

Il contrôle d'abord que le certificat enregistré dans :

```bash
EXPECTED_SIGNING_CERT_SHA1
```

est toujours une identité valide dans le trousseau.

Après compilation, il extrait également le certificat réellement utilisé pour signer `LettresEtScores.app` et calcule son empreinte SHA‑1.

Les deux valeurs doivent être identiques.

Exemple :

```text
[LettresEtScores] Certificat attendu : ABCDEF...
[LettresEtScores] Certificat utilisé  : ABCDEF...
[LettresEtScores] Certificat de signature conforme.
```

Si elles diffèrent, l'application **n'est pas installée**.

Cette vérification vise notamment à éviter qu'un nouveau certificat soit installé silencieusement et provoque une nouvelle demande « Développeur non approuvé » sur l'iPhone.


## 12. Que faire si le certificat change ?

Afficher les identités valides :

```bash
security find-identity -v -p codesigning
```

Les certificats accompagnés de :

```text
(CSSMERR_TP_CERT_REVOKED)
```

sont révoqués et ne doivent pas être utilisés.

Si le certificat précédemment épinglé n'existe plus, relancer simplement :

```bash
Tools/install-renew-ios.sh
```

L'installateur lit la configuration existante.

S'il constate que le certificat précédemment utilisé n'est plus disponible et qu'un autre certificat doit être adopté, il affiche :

- l'ancienne empreinte ;
- la nouvelle empreinte ;

et demande une confirmation explicite avant de modifier la configuration.

Il ne doit donc pas adopter silencieusement un nouveau certificat.

Pour un changement volontaire déjà vérifié, on peut aussi utiliser :

```bash
Tools/install-renew-ios.sh --accept-new-cert
```

ou imposer explicitement l'empreinte :

```bash
Tools/install-renew-ios.sh \
  --cert NOUVELLE_EMPREINTE_SHA1
```

Après installation d'une application signée avec un nouveau certificat, iOS peut demander une nouvelle approbation du développeur.



## 13. Message « Développeur non approuvé »

Lors de la première installation avec une identité Apple Development donnée, ou après un changement de certificat, iOS peut afficher :

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

Le libellé exact peut varier selon la version d'iOS.

Cette approbation devrait normalement rester valable tant que la même identité de développement est utilisée.



## 14. Vérification du profil de provisioning

Après compilation, `renew-ios-wifi.sh` lit :

```text
LettresEtScores.app/embedded.mobileprovision
```

et extrait notamment :

- l'UUID du profil ;
- sa date d'expiration.

La réussite d'un build ne signifie pas nécessairement qu'un nouveau profil a été créé : Xcode peut réutiliser un profil encore valable.

Par défaut, le script considère qu'un profil fraîchement renouvelé doit disposer d'au moins :

```text
120 heures
```

de validité restante.

Si Xcode réutilise encore un ancien profil proche de son expiration, l'application n'est pas réinstallée inutilement et une nouvelle tentative est programmée.



## 15. Installation par Wi‑Fi

Si toutes les vérifications sont satisfaites, l'application est installée avec :

```bash
xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  "/chemin/LettresEtScores.app"
```

Le script ne désinstalle pas volontairement l'application existante.

La nouvelle build conserve le même Bundle Identifier, ce qui permet normalement de préserver les données de l'application.


# Automatisation

## 16. Fonctionnement du LaunchAgent

L'installateur charge automatiquement :

```text
be.bartjourquin.lettresetcores.renew-ios
```

Le LaunchAgent lance périodiquement :

```text
Tools/renew-ios-wifi.sh
```

Le script examine d'abord :

```text
~/.local/state/lettres-et-scores/renew-ios.state
```

Si la prochaine fenêtre de renouvellement n'est pas encore atteinte, il quitte immédiatement.

Si l'iPhone est absent ou non joignable, il quitte également sans effectuer de build.

Le LaunchAgent réessaiera lors d'une exécution ultérieure.


## 17. Journaux

Les sorties standard sont écrites dans :

```text
/tmp/lettres-et-scores-renew.log
```

Les erreurs sont écrites dans :

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


## 18. Forcer un test ou un renouvellement

Pour ignorer temporairement la prochaine date enregistrée :

```bash
Tools/renew-ios-wifi.sh --force
```

Cette commande force une tentative, mais les contrôles du certificat, du DDI et du provisioning restent actifs.


## 19. Réinstaller ou mettre à jour la procédure

`install-renew-ios.sh` est conçu pour pouvoir être relancé.

Par exemple après :

- une mise à jour du script ;
- un déplacement du dépôt ;
- un changement d'iPhone ;
- un changement de certificat ;
- une modification de la configuration de Xcode.

Exécuter :

```bash
Tools/install-renew-ios.sh
```

Lorsqu'un fichier de configuration ou un LaunchAgent existe déjà, l'installateur en crée une sauvegarde horodatée avant de le remplacer.

Exemple :

```text
renew-ios.conf.bak-20260906-180000
be.bartjourquin.lettresetcores.renew-ios.plist.bak-20260906-180000
```


# Dépannage

## 20. Aucun iPhone n'est détecté

Tester :

```bash
xcrun devicectl list devices
```

Puis :

```bash
xcrun devicectl device info details \
  --device VOTRE_DEVICE_ID
```

Vérifier :

- que l'iPhone est allumé ;
- qu'il est déverrouillé ;
- qu'il a déjà été appairé avec ce Mac ;
- que le Mac et l'iPhone peuvent communiquer sur le réseau.



## 21. Plusieurs appareils sont détectés

L'installateur affiche un menu.

On peut également préciser directement l'appareil :

```bash
Tools/install-renew-ios.sh \
  --device COREDEVICE_ID
```


## 22. Plusieurs certificats sont détectés

L'installateur affiche les identités Apple Development valides et demande laquelle doit être utilisée.

On peut imposer une empreinte :

```bash
Tools/install-renew-ios.sh \
  --cert EMPREINTE_SHA1
```


## 23. Xcode ne trouve pas l'iPhone comme destination

Depuis la racine du dépôt :

```bash
xcodebuild \
  -project LettresEtScores.xcodeproj \
  -scheme LettresEtScores \
  -showdestinations
```

La ligne correspondant à l'iPhone doit apparaître sans champ `error:`.

Si elle contient une erreur relative au Developer Disk Image, reprendre la procédure de préparation DDI décrite plus haut.


## 24. Le script compile mais n'installe rien

Afficher l'état :

```bash
Tools/renew-ios-wifi.sh --status
```

Il est possible que :

- le profil actuel soit encore suffisamment valable ;
- Xcode ait réutilisé un ancien profil ;
- le certificat de signature ne corresponde plus au certificat attendu ;
- l'iPhone ne soit plus joignable ;
- le DDI ne soit pas disponible.

Consulter également :

```bash
tail -100 /tmp/lettres-et-scores-renew-error.log
```


# Désinstallation

## 25. Désinstaller la procédure

La méthode recommandée est :

```bash
Tools/install-renew-ios.sh --uninstall
```

Cette commande décharge le LaunchAgent et supprime :

```text
~/.config/lettres-et-scores/renew-ios.conf
~/Library/LaunchAgents/be.bartjourquin.lettresetcores.renew-ios.plist
```

Elle ne désinstalle pas `Lettres & Scores` de l'iPhone.

Elle conserve volontairement le fichier d'état.

Pour le supprimer également :

```bash
rm -rf ~/.local/state/lettres-et-scores
```


# Résumé

Après la préparation initiale de l'iPhone dans Xcode, l'installation normale se résume à :

```bash
chmod +x Tools/install-renew-ios.sh Tools/renew-ios-wifi.sh
Tools/install-renew-ios.sh
```

Le cycle automatisé devient ensuite :

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

Tant que :

- le Mac est allumé ;
- l'iPhone est accessible ;
- Xcode reste correctement configuré ;
- le certificat attendu reste valide ;

le renouvellement peut fonctionner sans intervention manuelle régulière.

Cette automatisation reste toutefois expérimentale et doit être considérée comme une aide pratique, pas comme un mécanisme officiel ou garanti par Apple.
