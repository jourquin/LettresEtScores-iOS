# Lettres & Scores — iOS

Lettres & Scores est une application iOS écrite en Swift qui recherche les mots français réalisables à partir d'un tirage de lettres, avec prise en charge des jokers, du calcul des points et de contraintes de recherche par expressions régulières.

Ce projet est le portage iOS de [LettresEtScores-Python](https://github.com/jourquin/LettresEtScores-Python).

## Fonctionnalités

- normalisation des tirages de 2 à 15 lettres ;
- prise en charge des lettres accentuées, des séparateurs et des jokers (`?`) ;
- recherche des mots réalisables dans un dictionnaire embarqué ;
- calcul du score selon la valeur française des lettres ;
- score nul pour une lettre remplacée par un joker ;
- classement par longueur et par score ;
- filtrage par une ou plusieurs expressions régulières séparées par `;` ;
- chargement du dictionnaire depuis une ressource incluse dans l'application ;
- tests unitaires avec Swift Testing.

## Prérequis

- Xcode ;
- un SDK iOS compatible avec le projet ;
- le fichier lexical `ods9.txt` ajouté aux ressources de la cible de l'application.

## Dictionnaire `ods9.zip` : origine et avertissement

Le fichier `LettresEtScores/Resources/ods9.zip`, qui contient le fichier `ods9.txt` comme seule entrée, a été créé à partir des données encodées dans le dépôt tiers [Thecoolsim/ODS9](https://github.com/Thecoolsim/ODS9), attribué dans ce dépôt à Simon Adjatan.

Le dépôt source comporte une licence MIT. Sa documentation ne précise toutefois pas séparément et sans ambiguïté le statut juridique des données lexicales encodées dans `words.js`. Par conséquent :

- la licence MIT du présent projet couvre le code de Lettres & Scores, mais ne prétend pas accorder de droits supplémentaires sur `ods9.txt` ni sur les données lexicales tierces dont il est dérivé ;
- la présence d'`ods9.txt` dans ce dépôt ne signifie pas que cette liste constitue une publication officielle de Larousse, de la Fédération internationale de Scrabble francophone (FISF) ou de toute autre institution ;
- cette liste ne constitue pas, à elle seule, une référence homologuée pour la compétition ;


Le dictionnaire est fourni pour les besoins du projet, sans garantie d'exhaustivité, d'exactitude ni d'adéquation à un usage particulier.

## Installation du dictionnaire dans Xcode

Placez le fichier sous le nom exact :

```text
LettresEtScores/Resources/ods9.txt
```

Vérifiez ensuite dans Xcode qu'il appartient bien à la cible de l'application. Le moteur peut alors être initialisé avec :

```swift
let finder = try WordFinder(resource: "ods9")
```

La casse du nom de fichier doit être respectée, notamment sur un appareil iOS réel.

## Tests

Les tests unitaires couvrent notamment :

- la normalisation et la validation des tirages ;
- la recherche, le score et l'utilisation des jokers ;
- le classement déterministe des résultats ;
- les contraintes par expressions régulières ;
- le chargement d'une liste de mots depuis une ressource embarquée.

Ils peuvent être lancés depuis le navigateur de tests de Xcode (`⌘6`) ou avec la commande `xcodebuild` adaptée au schéma et au simulateur utilisés.

## Portage assisté par ChatGPT

Le portage de la version Python vers Swift et iOS a été réalisé par Bart Jourquin avec l'aide de ChatGPT (OpenAI). ChatGPT a notamment servi d'assistant pour traduire et structurer le moteur, proposer des tests et accompagner l'intégration progressive dans Xcode.

Les propositions générées avec cette assistance ont été relues, intégrées et validées dans le cadre du projet. Cette mention décrit le processus de développement ; elle ne transfère à OpenAI ni la responsabilité de maintenance du projet ni les droits sur les données lexicales tierces.

## Licence

Le code source de Lettres & Scores est distribué sous licence MIT. Consultez le fichier [LICENSE](LICENSE).

Cette licence ne modifie pas les droits éventuellement applicables à `ods9.txt` ou aux autres contenus provenant de tiers. Consultez également la section [Dictionnaire `ods9.txt` : origine et avertissement](#dictionnaire-ods9txt--origine-et-avertissement).

## Auteur

Bart Jourquin
