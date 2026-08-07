//
//  SearchViewModelTests.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Testing
@testable import LettresEtScores

@MainActor
struct SearchViewModelTests {
    @Test
    func returnsBothRankings() async throws {
        let finder = try WordFinder(
            words: [
                "AXE",
                "CHAT",
                "CHATS",
                "JAZZ",
                "JURA",
                "TAXI",
                "ZOO"
            ]
        )

        let viewModel = SearchViewModel(
            finder: finder
        )

        viewModel.rack = "CHATS"

        await viewModel.search()

        guard case .results(let result) =
            viewModel.state
        else {
            Issue.record(
                "Un résultat était attendu."
            )
            return
        }

        #expect(result.possibleCount == 2)
        #expect(result.longest.first?.word == "CHATS")
        #expect(
            result.highestScoring.first?.score == 10
        )
    }

    @Test
    func appliesConstraints() async throws {
        let finder = try WordFinder(
            words: ["CHAT", "CHATS", "TAXI"]
        )

        let viewModel = SearchViewModel(
            finder: finder
        )

        viewModel.rack = "CHATS"
        viewModel.constraints = "^CHAT$"

        await viewModel.search()

        guard case .results(let result) =
            viewModel.state
        else {
            Issue.record(
                "Un résultat était attendu."
            )
            return
        }

        #expect(result.possibleCount == 1)
        #expect(result.longest.first?.word == "CHAT")
    }

    @Test
    func exposesRackValidationError() async throws {
        let finder = try WordFinder(
            words: ["CHAT"]
        )

        let viewModel = SearchViewModel(
            finder: finder
        )

        viewModel.rack = "A"

        await viewModel.search()

        guard case .failed(let message) =
            viewModel.state
        else {
            Issue.record(
                "Une erreur était attendue."
            )
            return
        }

        #expect(
            message ==
            "Saisissez au moins 2 lettres ou jokers."
        )
    }
}
