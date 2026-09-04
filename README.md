# Lettres & Scores — iOS

Lettres & Scores est une application iOS écrite en Swift et SwiftUI. Elle
recherche les mots réalisables à partir d'un tirage de lettres avec la liste
ODS9 embarquée.

Ce projet est le portage iOS de
[`LettresEtScores-Python`](https://github.com/jourquin/LettresEtScores-Python). Ce portage a été réalisé avec l'aide de ChatGPT.

## Fonctionnalités

- normalisation et validation des tirages de 2 à 15 tuiles ;
- lettres accentuées, séparateurs et deux jokers au maximum (`?` ou `*`) ;
- recherche dans la liste ODS9 disponible hors ligne ;
- calcul des points avec score nul pour les lettres fournies par un joker ;
- classement par longueur et par score ;
- sélection de 1 à 20 résultats par classement, 10 par défaut ;
- contraintes par expressions régulières, séparées par `;` ;
- vérification exacte d'un mot lorsque le tirage est vide ;
- décompression et indexation en arrière-plan, sans extraction sur disque ;
- consultation facultative du Wiktionnaire ;
- tests unitaires avec Swift Testing et tests d'interface avec XCUITest.

## Prérequis et lancement

- un Mac équipé de Xcode ;
- iOS 17.6 ou une version ultérieure pour l'appareil ou le simulateur.

Clonez le dépôt puis ouvrez le projet :

```bash
git clone https://github.com/jourquin/LettresEtScores-iOS.git
open LettresEtScores-iOS/LettresEtScores.xcodeproj
```

La liste de mots est déjà incluse. Aucune dépendance tierce ni étape de
construction supplémentaire n'est nécessaire pour lancer l'application.

Une connexion Internet est requise uniquement pour les définitions du
Wiktionnaire.

### Installation sur un iPhone

1. Ajoutez votre compte Apple dans **Xcode → Settings → Accounts**.
2. Ouvrez la cible `LettresEtScores`, puis **Signing & Capabilities**.
3. Activez **Automatically manage signing** et choisissez votre équipe.
4. Connectez et déverrouillez l'iPhone, puis sélectionnez-le comme destination.
5. Activez le mode développeur sur l'iPhone si Xcode le demande.
6. Lancez l'application avec **Run** (`⌘R`).

Un compte Apple gratuit suffit pour une installation personnelle, mais le
profil expire après sept jours. Apple détaille les possibilités dans
[`Choosing a Membership`](https://developer.apple.com/support/compare-memberships/)
et la procédure appareil dans
[`Enabling Developer Mode`](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

### Renouvellement expérimental d'une installation Personal Team

Le dépôt contient également un script exploratoire permettant de tenter le
renouvellement et la réinstallation de l'application sur un iPhone appairé,
sans ouvrir manuellement Xcode à chaque expiration du profil. Il utilise
`xcodebuild`, `devicectl` et, en option, un `LaunchAgent` macOS pour automatiser
les tentatives de renouvellement par Wi-Fi.

Cette méthode est **expérimentale**. Elle a été mise au point à partir de tests
sur une configuration particulière, mais sa robustesse n'a pas été démontrée
sur d'autres versions de macOS, Xcode ou iOS, ni sur d'autres comptes et
appareils. Apple peut également modifier le comportement de la signature, du
provisioning, des Developer Disk Images ou des outils en ligne de commande.
Le script ne doit donc pas être considéré comme un mécanisme officiel ou
garanti de renouvellement.

Il inclut plusieurs contrôles de sécurité, notamment la vérification du
certificat Apple Development réellement utilisé pour signer l'application,
mais son utilisation reste à la charge de l'utilisateur. Une intervention
manuelle peut redevenir nécessaire après une mise à jour d'iOS ou de Xcode, un
changement ou une révocation de certificat, ou une nouvelle demande
d'approbation du développeur sur l'iPhone.

La procédure complète, les prérequis, le diagnostic et la mise en place de
l'automatisation sont décrits dans
[`RENEW_IOS_WIFI.md`](RENEW_IOS_WIFI.md).

## Utilisation

1. Saisissez de 2 à 15 lettres dans **Tirage**.
2. Utilisez `?` ou `*` pour représenter un joker.
3. Ajoutez éventuellement des motifs dans **Contraintes**.
4. Choisissez le nombre de résultats et appuyez sur **Rechercher**.
5. Touchez un résultat pour consulter le Wiktionnaire.

Pour vérifier une forme exacte, laissez **Tirage** vide, saisissez le mot dans
**Contraintes**, puis appuyez sur **Vérifier**. Le résultat indique seulement
la présence dans la liste ODS9 tierce embarquée ; il ne constitue pas une
validation officielle pour une compétition.

## Liste ODS9 embarquée

`Resources/ods9.deflate` contient la liste publiée dans `words.js` par le dépôt
tiers [`Thecoolsim/ODS9`](https://github.com/Thecoolsim/ODS9).

| Contenu | Nombre de formes |
| --- | ---: |
| Ressource complète, longueurs 2 à 21 | 416 349 |
| Index du moteur, longueurs 2 à 15 | 407 128 |
| Formes conservées mais non indexées, longueurs 16 à 21 | 9 221 |

Le fichier `.deflate` est un flux DEFLATE brut, pas une archive ZIP. Après
décompression, il contient les formes uniques, triées et composées uniquement
des lettres `A` à `Z`, à raison d'une forme par ligne. Le moteur ignore les
formes de plus de 15 lettres.

Empreintes de la ressource embarquée :

```text
ods9.deflate : 64819c01a590e7a18368add5b48316632bd7f053b158178e69603aacb3f08b62
texte décompressé : a3e92f5a5044229e3daad6d56152ef2c4fa9e0ec4e69805571fdeffe341ce6c7
```

Cette source n'est pas une publication officielle de Larousse ou de la FISF.
Le dépôt tiers possède sa propre licence, mais aucune licence explicite propre
aux données lexicales ODS9 n'a été identifiée. Il appartient à chaque
redistributeur de vérifier les droits applicables à la liste.

## Reconstruction de la ressource

Le répertoire `Tools` contient notamment `build_ods9.py`. Ce script télécharge
`words.js` à une révision Git figée, contrôle son SHA-256, décode le contenu
gzip/Base64, valide les 416 349 formes et crée le flux DEFLATE brut attendu par
Foundation.

```bash
python3 Tools/build_ods9.py
```

Pour utiliser une copie locale de `words.js` :

```bash
python3 Tools/build_ods9.py --source /chemin/vers/words.js
```

Pour contrôler la ressource existante sans réseau ni modification :

```bash
python3 Tools/build_ods9.py --check
```

Le script utilise uniquement la bibliothèque standard de Python.

## Parité avec la version Python

La comparaison a été effectuée avec le commit Python
[`b97df019`](https://github.com/jourquin/LettresEtScores-Python/commit/b97df0199fba10216258a5b11a06d3b2e26a1e5d).

| Fonction | Python | iOS |
| --- | :---: | :---: |
| Liste ODS9 et limite de 15 lettres | oui | oui |
| Accents, ligatures, séparateurs et jokers | oui | oui |
| Classements par longueur et par score | oui | oui |
| Nombre de résultats configurable de 1 à 20 | oui | oui |
| Contraintes régulières multiples | oui | oui |
| Vérification exacte d'un mot | oui | oui |
| Définition d'un résultat ou d'un mot vérifié | oui | oui |
| Chargement hors du thread d'interface | oui | oui |

Aucune nouvelle fonctionnalité métier du commit Python courant ne manque dans
le portage iOS. Les différences restantes sont liées aux plateformes : les
deux classements sont affichés côte à côte sur ordinateur et par sélecteur sur
iPhone ; les clients Wiktionnaire utilisent les API et présentations propres à
chaque interface.

## Tests

Le projet contient **40 tests unitaires** et **6 tests d'interface**. Ils
couvrent notamment le moteur, les jokers, les contraintes, la vérification
exacte, le chargement DEFLATE, l'index ODS9 embarqué, le Wiktionnaire et les
principaux parcours SwiftUI.

Les tests se lancent depuis le navigateur de tests de Xcode (`⌘6`) ou avec
`xcodebuild` et un simulateur compatible.

Le générateur dispose également d'un contrôle autonome :

```bash
python3 Tools/build_ods9.py --check
```

## Licence

Le code source de Lettres & Scores est distribué sous licence MIT. Consultez
[`LICENSE`](LICENSE). La liste ODS9 tierce suit les droits applicables à sa
source.

## Auteur

Bart Jourquin
