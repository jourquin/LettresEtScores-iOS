//
//  DefinitionView.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//


import SwiftUI

struct DefinitionView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel:
        DefinitionViewModel

    init(
        word: String,
        loader: @escaping DefinitionLoader =
            DefinitionLoaders.live
    ) {
        _viewModel = StateObject(
            wrappedValue: DefinitionViewModel(
                word: word,
                loader: loader
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView

                case .loaded(let definition):
                    loadedView(definition)

                case .failed(let message):
                    failedView(message)
                }
            }
            .navigationTitle(viewModel.word)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()

            Text("Consultation du Wiktionnaire…")
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func loadedView(
        _ definition: WordDefinition
    ) -> some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                Text(definition.extract)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .textSelection(.enabled)
                    .accessibilityIdentifier(
                        "definitionExtract"
                    )

                Text(
                    "Extrait du Wiktionnaire. "
                    + "Le contenu reste soumis "
                    + "à sa licence."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Link(
                    "Ouvrir la page complète",
                    destination: definition.sourceURL
                )
                .accessibilityIdentifier("fullDefinitionLink")
            }
            .padding()
        }
    }

    private func failedView(
        _ message: String
    ) -> some View {
        ContentUnavailableView {
            Label(
                "Définition indisponible",
                systemImage:
                    "exclamationmark.triangle"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Réessayer") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
