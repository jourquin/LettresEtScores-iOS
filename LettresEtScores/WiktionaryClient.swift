//
//  WiktionaryClient.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation

struct WordDefinition: Equatable, Identifiable, Sendable {
    let word: String
    let extract: String
    let sourceURL: URL

    var id: String {
        word
    }
}

enum WiktionaryClientError:
    Error,
    Equatable,
    Sendable
{
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case notFound
    case emptyExtract
    case invalidData
}

struct WiktionaryClient: Sendable {
    typealias Loader = @Sendable (
        URLRequest
    ) async throws -> (Data, URLResponse)

    private let loader: Loader

    init(session: URLSession = .shared) {
        loader = { request in
            try await session.data(for: request)
        }
    }

    init(loader: @escaping Loader) {
        self.loader = loader
    }

    func definition(
        for word: String
    ) async throws -> WordDefinition {
        let normalizedWord = word
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased(
                with: Locale(identifier: "fr_FR")
            )

        guard
            var components = URLComponents(
                string:
                    "https://fr.wiktionary.org/w/api.php"
            )
        else {
            throw WiktionaryClientError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(
                name: "action",
                value: "query"
            ),
            URLQueryItem(
                name: "format",
                value: "json"
            ),
            URLQueryItem(
                name: "formatversion",
                value: "2"
            ),
            URLQueryItem(
                name: "prop",
                value: "extracts"
            ),
            URLQueryItem(
                name: "redirects",
                value: "1"
            ),
            URLQueryItem(
                name: "explaintext",
                value: "1"
            ),
            URLQueryItem(
                name: "exchars",
                value: "1200"
            ),
            URLQueryItem(
                name: "titles",
                value: normalizedWord
            )
        ]

        guard let url = components.url else {
            throw WiktionaryClientError.invalidURL
        }

        var request = URLRequest(url: url)

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.setValue(
            "LettresEtScores-iOS/1.0 "
                + "(https://github.com/"
                + "jourquin/LettresEtScores-iOS)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await loader(
            request
        )

        guard let httpResponse =
            response as? HTTPURLResponse
        else {
            throw WiktionaryClientError
                .invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode
        else {
            throw WiktionaryClientError.httpStatus(
                httpResponse.statusCode
            )
        }

        let apiResponse: APIResponse

        do {
            apiResponse = try JSONDecoder().decode(
                APIResponse.self,
                from: data
            )
        } catch {
            throw WiktionaryClientError.invalidData
        }

        guard let page =
            apiResponse.query.pages.first,
            page.missing != true
        else {
            throw WiktionaryClientError.notFound
        }

        let extract = page.extract?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        guard !extract.isEmpty else {
            throw WiktionaryClientError.emptyExtract
        }

        guard let sourceBaseURL = URL(
            string: "https://fr.wiktionary.org/wiki"
        ) else {
            throw WiktionaryClientError.invalidURL
        }

        return WordDefinition(
            word: word,
            extract: extract,
            sourceURL: sourceBaseURL
                .appendingPathComponent(page.title)
        )
    }

    private struct APIResponse: Decodable {
        let query: Query
    }

    private struct Query: Decodable {
        let pages: [Page]
    }

    private struct Page: Decodable {
        let title: String
        let extract: String?
        let missing: Bool?
    }
}
