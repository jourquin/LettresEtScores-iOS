//
//  RackNormalizer.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation

struct NormalizedRack: Equatable, Sendable {
    let letters: String
    let jokerCount: Int

    var tileCount: Int {
        letters.count + jokerCount
    }
}

enum RackError: Error, Equatable {
    case unrecognizedCharacter(Character)
    case tooFewTiles
    case tooManyTiles
    case tooManyJokers
}

enum RackNormalizer {
    static let minimumTileCount = 2
    static let maximumTileCount = 15
    static let maximumJokerCount = 2

    static func normalize(_ raw: String) throws -> NormalizedRack {
        let expandedLigatures = raw
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "OE")
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "Æ", with: "AE")

        let normalized = expandedLigatures
            .folding(
                options: [.diacriticInsensitive],
                locale: Locale(identifier: "fr_FR")
            )
            .uppercased()

        var letters = ""
        var jokerCount = 0

        for character in normalized {
            if character >= "A" && character <= "Z" {
                letters.append(character)
            } else if character == "?" || character == "*" {
                jokerCount += 1
            } else if character.isWhitespace ||
                        ",;-_/".contains(character) {
                continue
            } else {
                throw RackError.unrecognizedCharacter(character)
            }
        }

        let tileCount = letters.count + jokerCount

        guard tileCount >= minimumTileCount else {
            throw RackError.tooFewTiles
        }

        guard tileCount <= maximumTileCount else {
            throw RackError.tooManyTiles
        }

        guard jokerCount <= maximumJokerCount else {
            throw RackError.tooManyJokers
        }

        return NormalizedRack(
            letters: letters,
            jokerCount: jokerCount
        )
    }
}
