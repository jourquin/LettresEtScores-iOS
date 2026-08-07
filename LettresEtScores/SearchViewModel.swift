//
//  SearchViewModel.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case searching
        case results(SearchResult)
        case failed(String)
    }

    @Published var rack = ""
    @Published var constraints = ""
    @Published private(set) var state: State = .idle

    private let finder: WordFinder

    init(finder: WordFinder) {
        self.finder = finder
    }

    var isSearching: Bool {
        if case .searching = state {
            return true
        }

        return false
    }

    var canSearch: Bool {
        !rack.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty && !isSearching
    }

    func search() async {
        guard !isSearching else {
            return
        }

        let finder = finder
        let rack = rack
        let constraints = constraints

        state = .searching

        let outcome = await Task.detached(
            priority: .userInitiated
        ) {
            do {
                let result = try finder.search(
                    rack,
                    rawConstraints: constraints
                )

                return SearchOutcome.success(result)
            } catch {
                return SearchOutcome.failure(
                    Self.message(for: error)
                )
            }
        }.value

        switch outcome {
        case .success(let result):
            state = .results(result)

        case .failure(let message):
            state = .failed(message)
        }
    }

    func clear() {
        guard !isSearching else {
            return
        }

        rack = ""
        constraints = ""
        state = .idle
    }

    nonisolated private static func message(
        for error: Error
    ) -> String {
        if let rackError = error as? RackError {
            switch rackError {
            case .unrecognizedCharacter(let character):
                return "Le caractère « \(character) » n’est pas autorisé."

            case .tooFewTiles:
                return "Saisissez au moins 2 lettres ou jokers."

            case .tooManyTiles:
                return "Le tirage ne peut pas dépasser 15 tuiles."

            case .tooManyJokers:
                return "Le tirage ne peut contenir que 2 jokers."
            }
        }

        if case let ConstraintError.invalidRegularExpression(pattern) =
            error
        {
            return "Expression régulière invalide : \(pattern)"
        }

        return "La recherche a échoué : \(error.localizedDescription)"
    }

    private enum SearchOutcome: Sendable {
        case success(SearchResult)
        case failure(String)
    }
}
