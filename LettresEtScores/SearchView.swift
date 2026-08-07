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

    private let wordCount: Int

    init(finder: WordFinder) {
        _viewModel = StateObject(
            wrappedValue: SearchViewModel(
                finder: finder
            )
        )

        wordCount = finder.wordCount
    }

    var body: some View {
        NavigationStack {
            Form {
                inputSection
                constraintsSection
                resultLimitSection
                searchSection
                stateSections
            }
            .navigationTitle("Lettres & Scores")
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("Effacer") {
                        viewModel.clear()
                    }
                    .disabled(
                        viewModel.isSearching ||
                        (
                            viewModel.rack.isEmpty &&
                            viewModel.constraints.isEmpty
                        )
                    )
                }
            }
            .sheet(
                isPresented: $isShowingConstraintHelp
            ) {
                ConstraintHelpView()
            }
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

            Text(
                "De 2 à 15 tuiles. Utilisez ? ou * "
                + "pour un joker."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var constraintsSection: some View {
        Section("Contraintes facultatives") {
            HStack {
                TextField(
                    "Ex. ^J..A$;R",
                    text: $viewModel.constraints
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

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

            Text(
                "Séparez plusieurs expressions "
                + "régulières par un point-virgule."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
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
                            : "Rechercher"
                    )

                    Spacer()
                }
            }
            .disabled(!viewModel.canSearch)
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

            Text(
                "Ce nombre s’applique séparément aux mots "
                + "les plus longs et aux meilleurs scores."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
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
        }
    }

    @ViewBuilder
    private func resultSections(
        _ result: SearchResult
    ) -> some View {
        Section("Résultat") {
            Text(possibleWordsText(result.possibleCount))

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
                    Array(candidates(from: result).enumerated()),
                    id: \.element.word
                ) { index, candidate in
                    CandidateRow(
                        rank: index + 1,
                        candidate: candidate
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
        if count == 0 {
            return "Aucun mot réalisable"
        }

        if count == 1 {
            return "1 mot réalisable"
        }

        return "\(count.formatted()) mots réalisables"
    }

    private enum Ranking: String, CaseIterable, Identifiable {
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
                .frame(width: 28, alignment: .trailing)

            Text(candidate.word)
                .font(.headline)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(candidate.score) pts")
                    .fontWeight(.semibold)

                Text("\(candidate.length) lettres")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
