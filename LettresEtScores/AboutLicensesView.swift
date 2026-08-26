//
//  AboutLicensesView.swift
//  LettresEtScores
//
//  Added on 10/08/2026.
//

import Foundation
import SwiftUI

struct AboutLicensesView: View {
    @Environment(\.dismiss) private var dismiss

    let wordCount: Int

    private let archiveWordCount = 416_349

    var body: some View {
        NavigationStack {
            List {
                Section("Application") {
                    LabeledContent(
                        "Nom",
                        value: "Lettres & Scores"
                    )

                    LabeledContent(
                        "Version",
                        value: versionDescription
                    )
                }

                Section("Liste ODS9") {
                    Text(
                        "La ressource embarquée contient "
                            + "\(archiveWordCount.formatted()) formes "
                            + "de 2 à 21 lettres. Le moteur en indexe "
                            + "\(wordCount.formatted()), de 2 à 15 "
                            + "lettres."
                    )
                    .accessibilityIdentifier("ods9Summary")

                    Text(
                        "La ressource est reconstruite à partir du "
                            + "fichier words.js publié par le dépôt "
                            + "tiers Thecoolsim/ODS9. Les 9 221 formes "
                            + "de 16 à 21 lettres restent dans la "
                            + "ressource, mais ne sont pas chargées par "
                            + "le moteur."
                    )

                    Text(
                        "Cette source n’est pas une publication "
                            + "officielle de Larousse ou de la FISF. "
                            + "La présence ou l’absence d’un mot ne "
                            + "constitue donc pas une validation "
                            + "officielle pour une compétition."
                    )
                    .foregroundStyle(.secondary)

                    externalLink(
                        "Source ODS9 tierce",
                        url: "https://github.com/Thecoolsim/ODS9"
                    )

                    externalLink(
                        "Code source de l’application",
                        url: "https://github.com/jourquin/LettresEtScores-iOS"
                    )
                }

                Section("Licences") {
                    Text(
                        "Le code de Lettres & Scores est distribué "
                            + "sous licence MIT."
                    )

                    Text(
                        "Le dépôt source tiers possède sa propre "
                            + "licence, mais aucune licence explicite "
                            + "propre aux données lexicales ODS9 n’a "
                            + "été identifiée. Vérifiez vos droits "
                            + "avant toute redistribution."
                    )
                    .foregroundStyle(.secondary)
                }

                Section("Définitions") {
                    Text(
                        "Les extraits de définitions sont consultés "
                            + "à la demande sur le Wiktionnaire et "
                            + "restent disponibles sous licence "
                            + "CC BY-SA 4.0, sauf mention contraire. "
                            + "Ils ne sont pas inclus dans la liste "
                            + "locale."
                    )

                    externalLink(
                        "Wiktionnaire en français",
                        url: "https://fr.wiktionary.org/"
                    )

                    externalLink(
                        "Licence et droit d’auteur",
                        url: "https://fr.wiktionary.org/wiki/Convention:Droit_d’auteur"
                    )
                }
            }
            .navigationTitle("À propos / Licences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var versionDescription: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"

        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "—"

        return "\(version) (\(build))"
    }

    @ViewBuilder
    private func externalLink(
        _ title: String,
        url: String
    ) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                Label(
                    title,
                    systemImage: "arrow.up.right.square"
                )
            }
        }
    }
}

#Preview {
    AboutLicensesView(wordCount: 407_128)
}
