//
//  WordListLoaderTests.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation
import Testing
@testable import LettresEtScores

private final class TestBundleToken {}

@MainActor
struct WordListLoaderTests {
    private var testBundle: Bundle {
        Bundle(for: TestBundleToken.self)
    }

    @Test
    func loadsWordsFromTextResource() throws {
        let words = try WordListLoader.loadWords(
            named: "test_words",
            bundle: testBundle
        )

        #expect(words.count == 9)
        #expect(words.first == "AXE")
        #expect(words.last == "ABCDEFGHIJKLMNOP")
    }

    @Test
    func buildsWordFinderFromResource() throws {
        let finder = try WordFinder(
            resource: "test_words",
            bundle: testBundle
        )

        // "chat" est un doublon de "CHAT" et le mot de
        // seize lettres est ignoré par WordFinder.
        #expect(finder.wordCount == 7)

        let result = try finder.search("CHATS")

        #expect(result.possibleCount == 2)
        #expect(result.longest.first?.word == "CHATS")
        #expect(result.longest.first?.score == 10)
    }

    @Test
    func rejectsMissingResource() {
        #expect(throws: WordListLoaderError.self) {
            try WordListLoader.loadWords(
                named: "missing_words",
                bundle: testBundle
            )
        }
    }
    
    @Test
    func loadsWordsFromCompressedResource() throws {
        let words = try WordListLoader.loadWords(
            fromCompressedResourceNamed: "test_words",
            bundle: testBundle
        )

        #expect(words.count == 9)
        #expect(words.first == "AXE")
        #expect(words.last == "ABCDEFGHIJKLMNOP")
    }

    @Test
    func buildsWordFinderFromCompressedResource() throws {
        let finder = try WordFinder(
            compressedResource: "test_words",
            bundle: testBundle
        )

        #expect(finder.wordCount == 7)

        let result = try finder.search("CHATS")

        #expect(result.possibleCount == 2)
        #expect(result.longest.first?.word == "CHATS")
        #expect(result.longest.first?.score == 10)
    }

    @Test
    func rejectsMissingCompressedResource() {
        #expect(throws: WordListLoaderError.self) {
            try WordListLoader.loadWords(
                fromCompressedResourceNamed: "missing_words",
                bundle: testBundle
            )
        }
    }
}
