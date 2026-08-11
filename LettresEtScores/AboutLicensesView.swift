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

                Section("Lexique français") {
                    Text(
                        "Le corpus embarqué contient "
                            + "\(wordCount.formatted()) formes de 2 à "
                            + "15 lettres. Il est dérivé de Morphalou "
                            + "3.1, conçu par Marie Tonnelier et "
                            + "maintenu par l’ATILF (CNRS et "
                            + "Université de Lorraine)."
                    )

                    Text(
                        "Les formes ont été filtrées, normalisées, "
                            + "dédoublonnées et triées le 9 août 2026. "
                            + "Ce lexique n’est ni une reproduction de "
                            + "l’ODS ni une référence officielle pour "
                            + "les compétitions."
                    )
                    .foregroundStyle(.secondary)

                    externalLink(
                        "Source Morphalou 3.1",
                        url: "https://hdl.handle.net/11403/morphalou/v3.1"
                    )

                    externalLink(
                        "Code source et corpus modifiable",
                        url: "https://github.com/jourquin/LettresEtScores-iOS"
                    )
                }

                Section("Licences") {
                    NavigationLink("Notice du corpus") {
                        LegalDocumentView(
                            title: "Notice du corpus",
                            resource: "NOTICE"
                        )
                    }
                    .accessibilityIdentifier("corpusNoticeLink")

                    NavigationLink("Licence LGPL-LR") {
                        LegalDocumentView(
                            title: "Licence LGPL-LR",
                            resource: "LICENSE-LGPL-LR"
                        )
                    }
                    .accessibilityIdentifier("corpusLicenseLink")
                }

                Section("Définitions") {
                    Text(
                        "Les extraits de définitions sont consultés "
                            + "à la demande sur le Wiktionnaire et "
                            + "restent disponibles sous licence "
                            + "CC BY-SA 4.0, sauf mention contraire. "
                            + "Ils ne sont pas inclus dans le corpus "
                            + "local."
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

private struct LegalDocumentView: View {
    let title: String
    let resource: String

    var body: some View {
        ScrollView {
            Text(documentText)
                .font(.footnote)
                .textSelection(.enabled)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var documentText: String {
        guard let url = Bundle.main.url(
            forResource: resource,
            withExtension: "txt"
        ),
        let text = try? String(
            contentsOf: url,
            encoding: .utf8
        ) else {
            return "Le document n’a pas pu être chargé."
        }

        return text
    }
}

#Preview {
    AboutLicensesView(wordCount: 402_448)
}
