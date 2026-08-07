//
//  WordFinderTests.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Testing
@testable import LettresEtScores

@MainActor
struct WordFinderTests {
    private let words = [
        "AXE",
        "CHAT",
        "CHATS",
        "JAZZ",
        "JURA",
        "TAXI",
        "ZOO"
    ]

    @Test
    func findsLongestWord() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search("CHATS")

        #expect(result.longest.first?.word == "CHATS")
        #expect(result.longest.first?.score == 10)
        #expect(result.possibleCount >= 2)
    }

    @Test
    func findsHighestScoringWord() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search("JAZZ")

        #expect(result.highestScoring.first?.word == "JAZZ")
        #expect(result.highestScoring.first?.score == 29)
    }

    @Test
    func jokerScoresZeroPoints() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search("JAZ?")

        let jazz = result.highestScoring.first {
            $0.word == "JAZZ"
        }

        #expect(jazz?.score == 19)
        #expect(result.jokerCount == 1)
    }

    @Test
    func usesAlphabeticalOrderToBreakTies() throws {
        let finder = try WordFinder(
            words: ["BA", "AB"]
        )
        let result = try finder.search("AB")

        #expect(
            result.longest.map(\.word) ==
            ["AB", "BA"]
        )
    }

    @Test
    func ignoresDuplicatesAndWordsOverFifteenLetters() throws {
        let finder = try WordFinder(
            words: [
                "CHAT",
                "chat",
                "ABCDEFGHIJKLMNOP"
            ]
        )

        #expect(finder.wordCount == 1)
    }
}
