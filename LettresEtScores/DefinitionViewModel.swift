//
//  DefinitionViewModel.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//


import Combine
import Foundation

@MainActor
final class DefinitionViewModel:
    ObservableObject
{
    enum State: Equatable {
        case idle
        case loading
        case loaded(WordDefinition)
        case failed(String)
    }

    typealias Loader = @Sendable (
        String
    ) async throws -> WordDefinition

    let word: String

    @Published private(set) var state:
        State = .idle

    private let loader: Loader

    init(
        word: String,
        loader: @escaping Loader = { word in
            try await WiktionaryClient()
                .definition(for: word)
        }
    ) {
        self.word = word
        self.loader = loader
    }

    func load() async {
        guard case .idle = state else {
            return
        }

        state = .loading

        do {
            state = .loaded(
                try await loader(word)
            )
        } catch {
            state = .failed(
                Self.message(for: error)
            )
        }
    }

    func retry() async {
        guard case .failed = state else {
            return
        }

        state = .idle
        await load()
    }

    private static func message(
        for error: Error
    ) -> String {
        if let clientError =
            error as? WiktionaryClientError
        {
            switch clientError {
            case .notFound:
                return
                    "Aucune entrée trouvée "
                    + "dans le Wiktionnaire."

            case .emptyExtract:
                return
                    "La page existe, mais aucun "
                    + "extrait n’est disponible."

            case .httpStatus,
                 .invalidURL,
                 .invalidResponse,
                 .invalidData:
                return
                    "Le Wiktionnaire a renvoyé "
                    + "une réponse invalide."
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Aucune connexion Internet."

            case .timedOut:
                return
                    "Le Wiktionnaire ne répond pas."

            default:
                break
            }
        }

        return
            "Impossible de charger cette définition."
    }
}