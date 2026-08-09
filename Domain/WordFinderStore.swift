//
//  WordFinderStore.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Combine
import Foundation

@MainActor
final class WordFinderStore: ObservableObject {
    enum State {
        case idle
        case loading
        case ready(WordFinder)
        case failed(String)
    }

    typealias Loader = @Sendable () throws -> WordFinder

    @Published private(set) var state: State = .idle

    private let loader: Loader

    init(
        loader: @escaping Loader = {
            try WordFinder(
                compressedResource: "lexique-francais"
            )
        }
    ) {
        self.loader = loader
    }

    func load() async {
        guard case .idle = state else {
            return
        }

        state = .loading

        let loader = loader

        let result = await Task.detached(
            priority: .userInitiated
        ) {
            do {
                return LoadResult.success(
                    try loader()
                )
            } catch {
                return LoadResult.failure(
                    String(describing: error)
                )
            }
        }.value

        switch result {
        case .success(let finder):
            state = .ready(finder)

        case .failure(let message):
            state = .failed(message)
        }
    }

    func retry() async {
        guard case .failed = state else {
            return
        }

        state = .idle
        await load()
    }

    private enum LoadResult: Sendable {
        case success(WordFinder)
        case failure(String)
    }
}
