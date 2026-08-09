<!-- Révision Morphalou/DEFLATE du 2026-08-09 -->

# Lettres & Scores — iOS

Lettres & Scores est une application iOS écrite en Swift et SwiftUI. Elle recherche les mots français réalisables à partir d’un tirage de lettres, avec prise en charge des jokers, du calcul des points et de contraintes de recherche par expressions régulières.

Ce projet est le portage iOS de [LettresEtScores-Python](https://github.com/jourquin/LettresEtScores-Python).

## Fonctionnalités

- normalisation et validation des tirages de 2 à 15 tuiles ;
- prise en charge des lettres accentuées, des séparateurs et des jokers (`?` ou `*`) ;
- recherche des mots réalisables dans un lexique français ouvert embarqué ;
- calcul du score selon la valeur française des lettres ;
- score nul pour une lettre remplacée par un joker ;
- classement des résultats par longueur et par score ;
- sélection de 1 à 20 résultats par classement, 10 par défaut ;
- aide intégrée pour la syntaxe des contraintes ;
- filtrage par une ou plusieurs expressions régulières séparées par `;` ;
- décompression native en mémoire du corpus DEFLATE, sans dépendance tierce ni extraction sur disque ;
- chargement et indexation du lexique en arrière-plan afin de ne pas bloquer l’interface ;
- interface SwiftUI de saisie, de recherche et d’affichage des résultats ;
- consultation d’un extrait de définition et de la page complète sur le Wiktionnaire ;
- tests unitaires avec Swift Testing et tests d’interface avec XCUITest.

## Prérequis

- un Mac équipé de Xcode ;
- iOS 17.6 ou une version ultérieure pour l’appareil ou le simulateur.

Une connexion à Internet est nécessaire pour consulter les définitions du Wiktionnaire. La recherche dans le lexique embarqué reste disponible hors ligne.

## Ouverture du projet

Clonez le dépôt, puis ouvrez `LettresEtScores.xcodeproj` dans Xcode :

```bash
git clone https://github.com/jourquin/LettresEtScores-iOS.git
open LettresEtScores-iOS/LettresEtScores.xcodeproj
```

Le lexique français ouvert est déjà inclus dans le dépôt. Le projet n’utilise aucune dépendance logicielle tierce : aucune copie de fichier ni installation manuelle n’est nécessaire.

Sélectionnez ensuite un simulateur ou un iPhone comme destination, puis lancez l’application avec **Run** (`⌘R`). L’installation sur un appareil physique nécessite en plus la configuration décrite ci-dessous.

## Installation sur un iPhone avec Xcode

L’application n’est pas distribuée sur l’App Store. Elle s’installe depuis son projet Xcode sur un iPhone physique.

### 1. Configurer un compte développeur Apple

Un compte Apple ajouté à Xcode comme compte développeur est nécessaire pour signer l’application. Un compte gratuit suffit pour l’installer sur ses propres appareils : Xcode l’affiche comme une **Personal Team**. L’adhésion payante à l’Apple Developer Program n’est requise que pour distribuer l’application ou utiliser certaines fonctionnalités avancées.

1. Dans Xcode, ouvrez **Xcode → Settings → Accounts**.
2. Ajoutez votre compte Apple s’il n’apparaît pas encore.
3. Ouvrez `LettresEtScores.xcodeproj`, sélectionnez la cible `LettresEtScores`, puis **Signing & Capabilities**.
4. Activez **Automatically manage signing** et choisissez votre équipe dans **Team**.
5. Si Xcode indique que l’identifiant de bundle est indisponible, remplacez-le par un identifiant qui vous est propre, par exemple `com.votrenom.LettresEtScores`.

Avec une Personal Team gratuite, le profil d’approvisionnement expire après 7 jours. Il faut alors reconstruire et réinstaller l’application depuis Xcode. Apple détaille les différences entre le compte gratuit et l’adhésion payante dans sa page [Choosing a Membership](https://developer.apple.com/support/compare-memberships/).

### 2. Connecter et préparer l’iPhone

1. Branchez l’iPhone au Mac, déverrouillez-le et acceptez **Faire confiance à cet ordinateur** lorsqu’iOS le demande.
2. Dans Xcode, sélectionnez l’iPhone comme destination d’exécution.
3. Si Xcode le demande, activez le mode développeur sur l’iPhone dans **Réglages → Confidentialité et sécurité → Mode développeur**.
4. Confirmez l’activation, laissez l’iPhone redémarrer, déverrouillez-le, puis confirmez une seconde fois le mode développeur. Cette procédure est décrite dans la documentation Apple [Enabling Developer Mode on a device](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

### 3. Installer et approuver l’application

1. Dans Xcode, lancez l’application avec **Run** (`⌘R`). Xcode la compile, la signe et l’installe sur l’iPhone.
2. Lors de la première ouverture, si iOS signale que le développeur n’est pas approuvé, ouvrez **Réglages → Général → VPN et gestion de l’appareil**.
3. Dans la rubrique **App du développeur**, sélectionnez l’identité associée au compte utilisé dans Xcode, puis choisissez **Faire confiance**, **Vérifier l’app** ou le libellé équivalent proposé par la version d’iOS. Une connexion à Internet peut être nécessaire pour vérifier le certificat.
4. Revenez à Xcode et relancez l’application, ou ouvrez-la depuis l’écran d’accueil.

La confiance accordée au Mac et l’approbation du développeur sont deux opérations distinctes. Le [guide Apple sur l’alerte « Faire confiance à cet ordinateur »](https://support.apple.com/109054) explique la première ; la seconde autorise l’exécution de l’application signée localement.

## Lexique français ouvert

`Resources/lexique-francais.deflate` contient **402 448 formes** construites à partir de [Morphalou 3.1](https://hdl.handle.net/11403/morphalou/v3.1), ressource de l’ATILF diffusée sous LGPL-LR.

Le corpus est généré sans consulter l’ODS. Les formes sont notamment corroborées par au moins deux lexiques d’origine dans Morphalou, normalisées en lettres `A–Z`, limitées à 2–15 lettres, dédoublonnées et triées. Il ne constitue ni une reproduction de l’ODS ni une référence officielle pour les compétitions.

Le fichier `.deflate` n’est pas une archive : après décompression, il contient uniquement les mots, à raison d’une forme par ligne. La licence, la notice de modification et le rapport de construction restent consultables séparément dans `Corpus/` :

- [LICENSE-Morphalou-LGPL-LR.txt](Corpus/LICENSE-Morphalou-LGPL-LR.txt) ;
- [NOTICE.txt](Corpus/NOTICE.txt) ;
- [BUILD-REPORT.json](Corpus/BUILD-REPORT.json).

La provenance, les critères complets, les statistiques, les empreintes et la commande de régénération sont détaillés dans [Corpus/README.md](Corpus/README.md).

## Tests

L’application comporte actuellement **35 tests unitaires et 3 tests d’interface**. Ils couvrent notamment :

- la normalisation et la validation des tirages ;
- la recherche, le score et l’utilisation des jokers ;
- le classement déterministe des résultats ;
- les contraintes par expressions régulières ;
- le chargement de listes de mots depuis des ressources texte et DEFLATE ;
- l’initialisation du moteur depuis une ressource compressée ;
- le chargement asynchrone unique du corpus et la gestion des erreurs ;
- le modèle de vue de recherche et l’exposition des deux classements ;
- la consultation du Wiktionnaire ;
- le parcours complet de recherche et d’ouverture d’une définition dans l’interface.

Les tests sont volontairement répartis entre deux cibles et deux dossiers :

- `LettresEtScoresTests` contient les tests unitaires rapides du moteur et des modèles de vue ;
- `LettresEtScoresUITests` lance l’application et vérifie son comportement visible avec XCUITest.

Cette séparation est la structure habituelle d’un projet Xcode : les tests d’interface ont besoin d’un processus distinct qui pilote l’application, contrairement aux tests unitaires.

Les tests peuvent être lancés depuis le navigateur de tests de Xcode (`⌘6`) ou avec la commande `xcodebuild` adaptée au schéma et au simulateur utilisés.

La chaîne de construction du corpus possède en plus **8 tests Python**, décrits dans [Corpus/README.md](Corpus/README.md#validation).

## Portage assisté par ChatGPT

Le portage de la version Python vers Swift et iOS a été réalisé avec l’aide de ChatGPT (OpenAI). ChatGPT a notamment servi d’assistant pour traduire et structurer le moteur, proposer des tests et accompagner l’intégration progressive dans Xcode et SwiftUI.

## Licence

Le code source de Lettres & Scores est distribué sous licence MIT. Consultez le fichier [LICENSE](LICENSE).

Le lexique dérivé de Morphalou est distribué séparément sous LGPL-LR. Consultez [Corpus/README.md](Corpus/README.md) et [Corpus/LICENSE-Morphalou-LGPL-LR.txt](Corpus/LICENSE-Morphalou-LGPL-LR.txt).

## Auteur

Bart Jourquin

