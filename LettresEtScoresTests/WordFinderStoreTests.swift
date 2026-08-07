//
//  WordFinderStoreTests.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation
import Testing
@testable import LettresEtScores

private enum TestLoadingError: Error {
    case failure
}

private final class LoadCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func makeFinder() throws -> WordFinder {
        lock.lock()
        count += 1
        lock.unlock()

        return try WordFinder(
            words: ["CHAT", "CHATS"]
        )
    }

    var value: Int {
        lock.lock()
        defer {
            lock.unlock()
        }

        return count
    }
}

@MainActor
struct WordFinderStoreTests {
    @Test
    func loadsFinderOnlyOnce() async {
        let counter = LoadCounter()

        let store = WordFinderStore {
            try counter.makeFinder()
        }

        await store.load()
        await store.load()

        switch store.state {
        case .ready(let finder):
            #expect(finder.wordCount == 2)

        default:
            Issue.record(
                "Le moteur devrait être prêt."
            )
        }

        #expect(counter.value == 1)
    }

    @Test
    func exposesLoadingFailure() async {
        let store = WordFinderStore {
            throw TestLoadingError.failure
        }

        await store.load()

        switch store.state {
        case .failed(let message):
            #expect(message.contains("failure"))

        default:
            Issue.record(
                "Une erreur de chargement était attendue."
            )
        }
    }
}
