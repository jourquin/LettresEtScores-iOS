//
//  ConstraintCompilerTests.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Testing
@testable import LettresEtScores

@MainActor
struct ConstraintCompilerTests {
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
    func compilesSemicolonSeparatedConstraints() throws {
        let constraints = try ConstraintCompiler.compile(
            "^j ; ; ^..r ; a$"
        )

        #expect(constraints.count == 3)
        #expect(
            ConstraintCompiler.matchesAll(
                "JURA",
                constraints: constraints
            )
        )
    }

    @Test
    func mandatoryLetterCanBeAnywhere() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search(
            "CHATS",
            rawConstraints: "s"
        )

        #expect(result.longest.map(\.word) == ["CHATS"])
    }

    @Test
    func enforcesFirstAndThirdPositions() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search(
            "CHATS",
            rawConstraints: "^c ; ^..a"
        )

        #expect(result.possibleCount == 2)
        #expect(
            result.longest.allSatisfy {
                $0.word.hasPrefix("C") &&
                $0.word[$0.word.index(
                    $0.word.startIndex,
                    offsetBy: 2
                )] == "A"
            }
        )
    }

    @Test
    func enforcesLastLetter() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search(
            "CHATS",
            rawConstraints: "s$"
        )

        #expect(result.longest.map(\.word) == ["CHATS"])
    }

    @Test
    func enforcesPenultimateLetter() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search(
            "CHATS",
            rawConstraints: "t.$"
        )

        #expect(result.longest.map(\.word) == ["CHATS"])
    }

    @Test
    func combinedConstraintsFindJura() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search(
            "AJURFOA",
            rawConstraints: "^j ; ^..r ; a$"
        )

        #expect(result.longest.map(\.word) == ["JURA"])
    }

    @Test
    func constraintDoesNotProvideMissingTile() throws {
        let finder = try WordFinder(words: words)
        let result = try finder.search(
            "HAT",
            rawConstraints: "^c"
        )

        #expect(result.possibleCount == 0)
    }

    @Test
    func rejectsInvalidRegularExpression() {
        #expect(throws: ConstraintError.self) {
            try ConstraintCompiler.compile("^[a")
        }
    }
}
