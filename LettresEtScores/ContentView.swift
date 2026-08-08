//
//  ContentView.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 06/08/2026.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WordFinderStore

    private let definitionLoader: DefinitionLoader

    init(
        store: WordFinderStore,
        definitionLoader: @escaping DefinitionLoader =
            DefinitionLoaders.live
    ) {
        _store = ObservedObject(
            wrappedValue: store
        )

        self.definitionLoader = definitionLoader
    }
    
    var body: some View {
        Group {
            switch store.state {
            case .idle, .loading:
                loadingView

            case .ready(let finder):
                SearchView(
                    finder: finder,
                    definitionLoader: definitionLoader
                )

            case .failed(let message):
                errorView(message: message)
            }
        }
        .task {
            await store.load()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()

            Text("Chargement du dictionnaire…")
                .font(.headline)

            Text(
                "Le corpus est décompressé et indexé "
                + "lors du lancement."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func errorView(
        message: String
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Chargement impossible")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Réessayer") {
                Task {
                    await store.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView(
        store: WordFinderStore {
            try WordFinder(
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
        }
    )
}
