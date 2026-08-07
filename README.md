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
- filtrage par une ou plusieurs expressions régulières séparées par `;` ;
- lecture du corpus `ods9.txt` directement depuis l’archive `ods9.zip`, sans extraction sur disque ;
- chargement et indexation du dictionnaire en arrière-plan, sans bloquer l’interface ;
- interface SwiftUI de saisie, de recherche et d’affichage des résultats ;
- tests unitaires avec Swift Testing.

## Prérequis

- Xcode ;
- un SDK iOS compatible avec la configuration du projet ;
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation), intégré avec Swift Package Manager ;
- l’archive lexicale `Resources/ods9.zip` incluse dans les ressources de la cible de l’application.

## Corpus ODS9 : origine et avertissement

L’archive `Resources/ods9.zip` contient le fichier lexical `ods9.txt`. Celui-ci a été créé à partir des données encodées dans le dépôt tiers [Thecoolsim/ODS9](https://github.com/Thecoolsim/ODS9), attribué dans ce dépôt à Simon Adjatan.

Le dépôt source comporte une licence MIT. Sa documentation ne précise toutefois pas séparément et sans ambiguïté le statut juridique des données lexicales encodées dans `words.js`. Par conséquent :

- la licence MIT du présent projet couvre le code de Lettres & Scores, mais ne prétend pas accorder de droits supplémentaires sur `ods9.txt`, sur `ods9.zip` ni sur les données lexicales tierces dont ils sont dérivés ;
- la présence de cette archive dans le dépôt ne signifie pas que la liste constitue une publication officielle de Larousse, de la Fédération internationale de Scrabble francophone (FISF) ou de toute autre institution ;
- cette liste ne constitue pas, à elle seule, une référence homologuée pour la compétition ;
- toute personne qui réutilise ou redistribue l’archive ou son contenu doit vérifier qu’elle dispose des droits nécessaires.

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

Le projet comporte actuellement **29 tests unitaires**. Ils couvrent notamment :

- la normalisation et la validation des tirages ;
- la recherche, le score et l’utilisation des jokers ;
- le classement déterministe des résultats ;
- les contraintes par expressions régulières ;
- le chargement de listes de mots depuis des ressources texte et ZIP ;
- l’initialisation du moteur depuis une archive ;
- le chargement asynchrone unique du corpus et la gestion des erreurs ;
- le modèle de vue de recherche et l’exposition des deux classements.

Les tests peuvent être lancés depuis le navigateur de tests de Xcode (`⌘6`) ou avec la commande `xcodebuild` adaptée au schéma et au simulateur utilisés.

## Portage assisté par ChatGPT

Le portage de la version Python vers Swift et iOS a été réalisé avec l’aide de ChatGPT (OpenAI). ChatGPT a notamment servi d’assistant pour traduire et structurer le moteur, proposer des tests et accompagner l’intégration progressive dans Xcode et SwiftUI.

## Licence

Le code source de Lettres & Scores est distribué sous licence MIT. Consultez le fichier [LICENSE](LICENSE).

Cette licence ne modifie pas les droits éventuellement applicables à `ods9.zip`, à `ods9.txt` ou aux autres contenus provenant de tiers. Consultez également la section [Corpus ODS9 : origine et avertissement](#corpus-ods9--origine-et-avertissement).

## Auteur

Bart Jourquin
