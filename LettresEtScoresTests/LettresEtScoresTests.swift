//
//  LettresEtScoresTests.swift
//  LettresEtScoresTests
//
//  Created by Bart Jourquin on 06/08/2026.
//

import Testing
@testable import LettresEtScores

@MainActor
struct RackNormalizerTests {
    @Test
    func acceptsAccentsSeparatorsAndJoker() throws {
        let rack = try RackNormalizer.normalize("ç, h â t ?")

        #expect(rack.letters == "CHAT")
        #expect(rack.jokerCount == 1)
        #expect(rack.tileCount == 5)
    }

    @Test
    func rejectsTooFewTiles() {
        #expect(throws: RackError.self) {
            try RackNormalizer.normalize("A")
        }
    }

    @Test
    func rejectsTooManyJokers() {
        #expect(throws: RackError.self) {
            try RackNormalizer.normalize("ABC???")
        }
    }

    @Test
    func acceptsFifteenTiles() throws {
        let rack = try RackNormalizer.normalize("ABCDEFGHIJKLMNO")

        #expect(rack.letters == "ABCDEFGHIJKLMNO")
        #expect(rack.jokerCount == 0)
        #expect(rack.tileCount == 15)
    }

    @Test
    func rejectsSixteenTiles() {
        #expect(throws: RackError.self) {
            try RackNormalizer.normalize("ABCDEFGHIJKLMNOP")
        }
    }
}
