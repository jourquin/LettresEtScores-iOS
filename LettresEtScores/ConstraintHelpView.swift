//
//  ConstraintHelpView.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import SwiftUI

struct ConstraintHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Double rôle") {
                    Text(
                        "Lorsque le tirage contient des lettres, "
                            + "ce champ filtre les mots réalisables "
                            + "avec les contraintes ci-dessous."
                    )

                    Text(
                        "Lorsque le tirage est vide, saisissez dans "
                            + "ce champ le mot exact dont vous voulez "
                            + "vérifier l’existence dans le corpus."
                    )
                }

                Section("Principaux symboles") {
                    ConstraintHelpRow(
                        pattern: "^",
                        explanation: "Début du mot"
                    )

                    ConstraintHelpRow(
                        pattern: "$",
                        explanation: "Fin du mot"
                    )

                    ConstraintHelpRow(
                        pattern: ".",
                        explanation: "Une lettre quelconque"
                    )

                    ConstraintHelpRow(
                        pattern: ".*",
                        explanation: "Zéro ou plusieurs lettres"
                    )

                    ConstraintHelpRow(
                        pattern: ";",
                        explanation: "Sépare plusieurs contraintes"
                    )
                }

                Section("Exemples") {
                    ConstraintHelpRow(
                        pattern: "A",
                        explanation: "Le mot contient A"
                    )

                    ConstraintHelpRow(
                        pattern: "^A",
                        explanation: "Le mot commence par A"
                    )

                    ConstraintHelpRow(
                        pattern: "E$",
                        explanation: "Le mot se termine par E"
                    )

                    ConstraintHelpRow(
                        pattern: "^..R",
                        explanation: "R est la troisième lettre"
                    )

                    ConstraintHelpRow(
                        pattern: "U.$",
                        explanation: "U est l’avant-dernière lettre"
                    )

                    ConstraintHelpRow(
                        pattern: "^....$",
                        explanation: "Mot de quatre lettres"
                    )

                    ConstraintHelpRow(
                        pattern: "^.{5,7}$",
                        explanation: "Mot de cinq à sept lettres"
                    )

                    ConstraintHelpRow(
                        pattern: "^J.R.*A$",
                        explanation:
                            "Commence par J, R en troisième "
                            + "position et finit par A"
                    )
                }

                Section {
                    Text(
                        "Toutes les contraintes séparées par "
                        + "un point-virgule doivent correspondre. "
                        + "Elles filtrent les résultats mais "
                        + "n’ajoutent aucune lettre au tirage."
                    )
                }
            }
            .navigationTitle("Aide aux contraintes")
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
        }
    }
}

private struct ConstraintHelpRow: View {
    let pattern: String
    let explanation: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(pattern)
                .font(
                    .system(
                        .body,
                        design: .monospaced
                    )
                )
                .fontWeight(.semibold)
                .frame(
                    width: 88,
                    alignment: .leading
                )

            Text(explanation)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ConstraintHelpView()
}
