//
//  WordFinder.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation

enum WordFinderError: Error, Equatable {
    case invalidWord(String)
    case invalidLimit
}

struct WordFinder {
    private struct Entry: Sendable {
        let word: String
        let counts: [UInt8]
        let baseScore: Int
    }

    private static let pointsByIndex = [
        1, 3, 3, 2, 1, 4, 2, 4, 1, 8, 10, 1, 2,
        1, 1, 3, 8, 1, 1, 1, 1, 4, 10, 10, 10, 10
    ]

    private let entriesByLength: [[Entry]]

    let wordCount: Int

    init(words: [String]) throws {
        var buckets = (0...RackNormalizer.maximumTileCount).map {
            _ in [Entry]()
        }

        var seen = Set<String>()

        for rawWord in words {
            let word = rawWord
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            guard !word.isEmpty else {
                continue
            }

            // Comme le moteur Python, les mots de plus de 15 lettres
            // sont simplement ignorés.
            guard word.count <= RackNormalizer.maximumTileCount else {
                continue
            }

            guard word.count >= RackNormalizer.minimumTileCount,
                  word.utf8.allSatisfy({ byte in
                      byte >= 65 && byte <= 90
                  })
            else {
                throw WordFinderError.invalidWord(word)
            }

            // Ignore les doublons, indépendamment de la casse.
            guard seen.insert(word).inserted else {
                continue
            }

            var counts = [UInt8](repeating: 0, count: 26)
            var baseScore = 0

            for byte in word.utf8 {
                let index = Int(byte - 65)

                counts[index] += 1
                baseScore += Self.pointsByIndex[index]
            }

            buckets[word.count].append(
                Entry(
                    word: word,
                    counts: counts,
                    baseScore: baseScore
                )
            )
        }

        entriesByLength = buckets
        wordCount = seen.count
    }

    func search(
        _ rawRack: String,
        limit: Int = 10,
        rawConstraints: String = ""
    ) throws -> SearchResult {
        guard limit >= 1 else {
            throw WordFinderError.invalidLimit
        }

        let rack = try RackNormalizer.normalize(rawRack)

        let constraints = try ConstraintCompiler.compile(
            rawConstraints
        )

        var rackCounts = [UInt8](repeating: 0, count: 26)

        for byte in rack.letters.utf8 {
            rackCounts[Int(byte - 65)] += 1
        }

        var longest: [Candidate] = []
        var highestScoring: [Candidate] = []
        var possibleCount = 0

        let maximumLength = min(
            RackNormalizer.maximumTileCount,
            rack.tileCount
        )

        for length in RackNormalizer.minimumTileCount...maximumLength {
            for entry in entriesByLength[length] {
                guard ConstraintCompiler.matchesAll(
                    entry.word,
                    constraints: constraints
                ) else {
                    continue
                }

                var missingCount = 0
                var jokerPenalty = 0
                var canBuildWord = true

                for index in 0..<26 {
                    let deficit =
                        Int(entry.counts[index]) -
                        Int(rackCounts[index])

                    guard deficit > 0 else {
                        continue
                    }

                    missingCount += deficit

                    if missingCount > rack.jokerCount {
                        canBuildWord = false
                        break
                    }

                    // Une lettre fournie par un joker ne rapporte aucun point.
                    jokerPenalty +=
                        deficit * Self.pointsByIndex[index]
                }

                guard canBuildWord else {
                    continue
                }

                possibleCount += 1

                let candidate = Candidate(
                    word: entry.word,
                    score: entry.baseScore - jokerPenalty
                )

                Self.insert(
                    candidate,
                    into: &longest,
                    limit: limit,
                    sortedBy: Self.longestFirst
                )

                Self.insert(
                    candidate,
                    into: &highestScoring,
                    limit: limit,
                    sortedBy: Self.highestScoreFirst
                )
            }
        }

        return SearchResult(
            longest: longest,
            highestScoring: highestScoring,
            possibleCount: possibleCount,
            normalizedLetters: rack.letters,
            jokerCount: rack.jokerCount
        )
    }

    private static func insert(
        _ candidate: Candidate,
        into candidates: inout [Candidate],
        limit: Int,
        sortedBy ordering: (Candidate, Candidate) -> Bool
    ) {
        candidates.append(candidate)
        candidates.sort(by: ordering)

        if candidates.count > limit {
            candidates.removeLast(candidates.count - limit)
        }
    }

    private static func longestFirst(
        _ lhs: Candidate,
        _ rhs: Candidate
    ) -> Bool {
        if lhs.length != rhs.length {
            return lhs.length > rhs.length
        }

        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }

        return lhs.word < rhs.word
    }

    private static func highestScoreFirst(
        _ lhs: Candidate,
        _ rhs: Candidate
    ) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }

        if lhs.length != rhs.length {
            return lhs.length > rhs.length
        }

        return lhs.word < rhs.word
    }
}
