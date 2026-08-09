# Lettres & Scores — iOS

Lettres & Scores est une application iOS écrite en Swift et SwiftUI. Elle recherche les mots français réalisables à partir d’un tirage de lettres, avec prise en charge des jokers, du calcul des points et de contraintes de recherche par expressions régulières.

Ce projet est le portage iOS de [LettresEtScores-Python](https://github.com/jourquin/LettresEtScores-Python).

## Fonctionnalités

- normalisation et validation des tirages de 2 à 15 tuiles ;
- prise en charge des lettres accentuées, des séparateurs et des jokers (`?` ou `*`) ;
- recherche des mots réalisables dans le corpus ODS9 embarqué ;
- calcul du score selon la valeur française des lettres ;
- score nul pour une lettre remplacée par un joker ;
- classement des résultats par longueur et par score ;
- sélection de 1 à 20 résultats par classement, 10 par défaut ;
- aide intégrée pour la syntaxe des contraintes ;
- filtrage par une ou plusieurs expressions régulières séparées par `;` ;
- lecture du corpus `ods9.txt` directement depuis l’archive `ods9.zip`, sans extraction sur disque ;
- chargement et indexation du dictionnaire en arrière-plan, sans bloquer l’interface ;
- interface SwiftUI de saisie, de recherche et d’affichage des résultats ;
- consultation d’un extrait de définition et de la page complète sur le Wiktionnaire ;
- tests unitaires avec Swift Testing et tests d’interface avec XCUITest.

## Prérequis

- un Mac équipé de Xcode ;
- iOS 17.6 ou une version ultérieure pour l’appareil ou le simulateur ;
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation), intégré avec Swift Package Manager ;
- l’archive lexicale `Resources/ods9.zip` incluse dans les ressources de la cible de l’application.

Une connexion à Internet est nécessaire pour consulter les définitions du Wiktionnaire. La recherche dans le corpus ODS9 reste disponible hors ligne.

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

## Corpus ODS9 : origine et avertissement

L’archive `Resources/ods9.zip` contient le fichier lexical `ods9.txt`. Celui-ci a été créé à partir des données encodées dans le dépôt tiers [Thecoolsim/ODS9](https://github.com/Thecoolsim/ODS9), attribué dans ce dépôt à Simon Adjatan.

Le dépôt source comporte une licence MIT. Sa documentation ne précise toutefois pas séparément et sans ambiguïté le statut juridique des données lexicales encodées dans `words.js`. Par conséquent :

- la licence MIT du présent projet couvre le code de Lettres & Scores, mais ne prétend pas accorder de droits supplémentaires sur `ods9.txt`, sur `ods9.zip` ni sur les données lexicales tierces dont ils sont dérivés ;
- la présence de cette archive dans le dépôt ne signifie pas que la liste constitue une publication officielle de Larousse, de la Fédération internationale de Scrabble francophone (FISF) ou de toute autre institution ;
- cette liste ne constitue pas, à elle seule, une référence homologuée pour la compétition ;


Le corpus est fourni pour les besoins du projet, sans garantie d’exhaustivité, d’exactitude ni d’adéquation à un usage particulier. Sa compression dans une archive ZIP ne modifie ni sa provenance ni les droits qui peuvent lui être applicables.

## Intégration du dictionnaire

L’archive doit se trouver sous le nom exact :

```text
Resources/ods9.zip
```

Elle doit contenir à sa racine une entrée nommée exactement :

```text
ods9.txt
```

Vérifiez dans Xcode que `ods9.zip` appartient bien à la cible de l’application. Le moteur est ensuite initialisé avec :

```swift
let finder = try WordFinder(archiveResource: "ods9")
```

`WordFinderStore` effectue cette opération une seule fois en arrière-plan au lancement. L’interface affiche successivement l’état de chargement, l’écran de recherche lorsque le moteur est prêt, ou un message permettant de réessayer en cas d’erreur.

La casse des noms de fichiers doit être respectée, notamment sur un appareil iOS réel.

## Dépendance ZIPFoundation

Le projet utilise [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) pour lire `ods9.txt` directement dans l’archive, sans créer de copie décompressée sur disque.

Le package doit apparaître à la fois :

- dans les dépendances Swift Package Manager du projet ;
- dans les frameworks et bibliothèques liés à la cible `LettresEtScores`.

## Tests

Le projet comporte actuellement **35 tests unitaires et 3 tests d’interface**. Ils couvrent notamment :

- la normalisation et la validation des tirages ;
- la recherche, le score et l’utilisation des jokers ;
- le classement déterministe des résultats ;
- les contraintes par expressions régulières ;
- le chargement de listes de mots depuis des ressources texte et ZIP ;
- l’initialisation du moteur depuis une archive ;
- le chargement asynchrone unique du corpus et la gestion des erreurs ;
- le modèle de vue de recherche et l’exposition des deux classements ;
- la consultation du Wiktionnaire ;
- le parcours complet de recherche et d’ouverture d’une définition dans l’interface.

Les tests peuvent être lancés depuis le navigateur de tests de Xcode (`⌘6`) ou avec la commande `xcodebuild` adaptée au schéma et au simulateur utilisés.

## Portage assisté par ChatGPT

Le portage de la version Python vers Swift et iOS a été réalisé avec l’aide de ChatGPT (OpenAI). ChatGPT a notamment servi d’assistant pour traduire et structurer le moteur, proposer des tests et accompagner l’intégration progressive dans Xcode et SwiftUI.

## Licence

Le code source de Lettres & Scores est distribué sous licence MIT. Consultez le fichier [LICENSE](LICENSE).

Cette licence ne modifie pas les droits éventuellement applicables à `ods9.zip`, à `ods9.txt` ou aux autres contenus provenant de tiers. Consultez également la section [Corpus ODS9 : origine et avertissement](#corpus-ods9--origine-et-avertissement).

## Auteur

Bart Jourquin
