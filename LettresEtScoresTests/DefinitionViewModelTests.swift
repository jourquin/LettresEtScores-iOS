//
//  DefinitionViewModelTests.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//


import Foundation
import Testing
@testable import LettresEtScores

@MainActor
struct DefinitionViewModelTests {
    @Test
    func exposesLoadedDefinition() async {
        let definition = WordDefinition(
            word: "CHAT",
            extract: "Animal domestique.",
            sourceURL: URL(
                string:
                    "https://fr.wiktionary.org/wiki/chat"
            )!
        )

        let viewModel = DefinitionViewModel(
            word: "CHAT"
        ) { _ in
            definition
        }

        await viewModel.load()

        #expect(
            viewModel.state == .loaded(definition)
        )
    }

    @Test
    func exposesMissingDefinition() async {
        let viewModel = DefinitionViewModel(
            word: "INTROUVABLE"
        ) { _ in
            throw WiktionaryClientError.notFound
        }

        await viewModel.load()

        #expect(
            viewModel.state == .failed(
                "Aucune entrée trouvée "
                + "dans le Wiktionnaire."
            )
        )
    }
}