//
//  SearchView.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel

    @State private var ranking: Ranking = .longest
    @State private var isShowingConstraintHelp = false
    @State private var isShowingAbout = false
    @State private var selectedDefinition: DefinitionSelection?

    private let wordCount: Int
    private let definitionLoader: DefinitionLoader

    init(
        finder: WordFinder,
        definitionLoader: @escaping DefinitionLoader =
            DefinitionLoaders.live
    ) {
        _viewModel = StateObject(
            wrappedValue: SearchViewModel(
                finder: finder
            )
        )

        wordCount = finder.wordCount
        self.definitionLoader = definitionLoader
    }

    var body: some View {
        NavigationStack {
            Form {
                inputSection
                constraintsSection

                if !viewModel.isWordCheckMode {
                    resultLimitSection
                }

                searchSection
                stateSections
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Lettres & Scores")
            .toolbar {
                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    Button {
                        isShowingAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("À propos et licences")
                    .accessibilityIdentifier("aboutButton")
                }

                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("Effacer") {
                        viewModel.clear()
                    }
                    .disabled(
                        viewModel.isSearching
                            || (
                                viewModel.rack.isEmpty
                                    && viewModel.constraints.isEmpty
                            )
                    )
                }
            }
        }
        .sheet(
            isPresented: $isShowingConstraintHelp
        ) {
            ConstraintHelpView()
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutLicensesView(wordCount: wordCount)
        }
        .sheet(item: $selectedDefinition) { selection in
            DefinitionView(
                word: selection.word,
                loader: definitionLoader
            )
        }
    }

    private var inputSection: some View {
        Section("Tirage") {
            TextField(
                "Ex. CHATS??",
                text: $viewModel.rack
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .accessibilityIdentifier("rackTextField")

            Text(
                "De 2 à 15 tuiles. Utilisez ? ou * "
                    + "pour un joker. Laissez vide pour "
                    + "vérifier un mot."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var constraintsSection: some View {
        Section("Contraintes") {
            HStack {
                TextField(
                    "Ex. ^J..A$;R",
                    text: $viewModel.constraints
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .accessibilityIdentifier("constraintsTextField")

                Button {
                    isShowingConstraintHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(
                    "Afficher l’aide sur les contraintes"
                )
            }

            Text("Contrainte(s) ou mot à vérifier si tirage vide")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var resultLimitSection: some View {
        Section("Affichage") {
            Stepper(
                value: $viewModel.resultLimit,
                in: SearchViewModel.resultLimitRange
            ) {
                Text(
                    "Résultats par classement : "
                        + "\(viewModel.resultLimit)"
                )
            }
        }
    }

    private var searchSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.search()
                }
            } label: {
                HStack {
                    Spacer()

                    if viewModel.isSearching {
                        ProgressView()
                            .padding(.trailing, 4)
                    }

                    Text(
                        viewModel.isSearching
                            ? "Recherche…"
                            : viewModel.actionTitle
                    )

                    Spacer()
                }
            }
            .disabled(!viewModel.canSearch)
            .accessibilityIdentifier("searchButton")
        }
    }

    @ViewBuilder
    private var stateSections: some View {
        switch viewModel.state {
        case .idle:
            Section {
                Text(
                    "\(wordCount.formatted()) mots indexés"
                )
                .foregroundStyle(.secondary)
            }

        case .searching:
            EmptyView()

        case .failed(let message):
            Section {
                Label(
                    message,
                    systemImage:
                        "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.red)
            }

        case .results(let result):
            resultSections(result)

        case .wordCheck(let result):
            wordCheckSection(result)
        }
    }

    private func wordCheckSection(
        _ result: WordCheckResult
    ) -> some View {
        Section("Vérification") {
            Label(
                result.exists
                    ? "« \(result.word) » figure dans le corpus."
                    : "« \(result.word) » ne figure pas dans le corpus.",
                systemImage: result.exists
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .foregroundStyle(
                result.exists ? Color.green : Color.orange
            )
            .accessibilityIdentifier("wordCheckResult")

            Button {
                selectedDefinition = DefinitionSelection(
                    word: result.word
                )
            } label: {
                Label(
                    "Voir la définition",
                    systemImage: "book"
                )
            }
            .accessibilityIdentifier(
                "wordCheckDefinitionButton"
            )
            .disabled(!result.exists)
            .foregroundStyle(
                result.exists ? Color.accentColor : Color.secondary
            )
            .opacity(result.exists ? 1 : 0.45)

            corpusNotice
        }
    }

    private var corpusNotice: some View {
        Text(
            "Le corpus est dérivé de Morphalou 3.1. "
                + "Ce résultat ne constitue pas une validation "
                + "officielle pour une compétition."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func resultSections(
        _ result: SearchResult
    ) -> some View {
        Section("Résultat") {
            Text(
                possibleWordsText(result.possibleCount)
            )

            Text(
                "Tirage normalisé : "
                    + normalizedRack(result)
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if result.possibleCount == 0 {
            Section {
                Text("Aucun mot trouvé.")
                    .foregroundStyle(.secondary)
            }
        } else {
            Section {
                Picker(
                    "Classement",
                    selection: $ranking
                ) {
                    ForEach(Ranking.allCases) { ranking in
                        Text(ranking.rawValue)
                            .tag(ranking)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                ForEach(
                    Array(
                        candidates(from: result).enumerated()
                    ),
                    id: \.element.word
                ) { index, candidate in
                    Button {
                        selectedDefinition =
                            DefinitionSelection(
                                word: candidate.word
                            )
                    } label: {
                        CandidateRow(
                            rank: index + 1,
                            candidate: candidate
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(
                        "candidate.\(candidate.word)"
                    )
                    .accessibilityHint(
                        "Affiche un extrait du Wiktionnaire"
                    )
                }
            }
        }
    }

    private func candidates(
        from result: SearchResult
    ) -> [Candidate] {
        switch ranking {
        case .longest:
            return result.longest

        case .highestScoring:
            return result.highestScoring
        }
    }

    private func normalizedRack(
        _ result: SearchResult
    ) -> String {
        result.normalizedLetters
            + String(
                repeating: "?",
                count: result.jokerCount
            )
    }

    private func possibleWordsText(
        _ count: Int
    ) -> String {
        switch count {
        case 0:
            return "Aucun mot réalisable"

        case 1:
            return "1 mot réalisable"

        default:
            return "\(count.formatted()) mots réalisables"
        }
    }

    private enum Ranking:
        String,
        CaseIterable,
        Identifiable
    {
        case longest = "Plus longs"
        case highestScoring = "Meilleurs scores"

        var id: Self {
            self
        }
    }
}

private struct CandidateRow: View {
    let rank: Int
    let candidate: Candidate

    var body: some View {
        HStack {
            Text("\(rank).")
                .foregroundStyle(.secondary)
                .frame(
                    width: 28,
                    alignment: .trailing
                )

            Text(candidate.word)
                .font(.headline)

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 2
            ) {
                Text("\(candidate.score) pts")
                    .fontWeight(.semibold)

                Text(
                    "\(candidate.length) lettres"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct DefinitionSelection: Identifiable {
    let word: String

    var id: String {
        word
    }
}

#Preview {
    SearchView(
        finder: try! WordFinder(
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
    )
}
