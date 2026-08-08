//
//  LettresEtScoresApp.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 06/08/2026.
//

import Foundation
import SwiftUI

@main
struct LettresEtScoresApp: App {
    @StateObject private var wordFinderStore:
        WordFinderStore

    private let definitionLoader: DefinitionLoader

    init() {
        let isUITesting = ProcessInfo.processInfo
            .arguments
            .contains("--ui-testing")

        if isUITesting {
            _wordFinderStore = StateObject(
                wrappedValue: WordFinderStore {
                    try WordFinder(
                        words: [
                            "CHAT",
                            "CHATS",
                            "TAXI"
                        ]
                    )
                }
            )

            definitionLoader = { word in
                guard let sourceURL = URL(
                    string:
                        "https://fr.wiktionary.org/wiki/"
                        + word.lowercased()
                ) else {
                    throw WiktionaryClientError.invalidURL
                }

                return WordDefinition(
                    word: word,
                    extract:
                        "Définition simulée pour \(word).",
                    sourceURL: sourceURL
                )
            }
        } else {
            _wordFinderStore = StateObject(
                wrappedValue: WordFinderStore()
            )

            definitionLoader = DefinitionLoaders.live
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                store: wordFinderStore,
                definitionLoader: definitionLoader
            )
        }
    }
}
