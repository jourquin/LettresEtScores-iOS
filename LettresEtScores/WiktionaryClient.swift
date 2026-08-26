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
        let trimmedWord = word
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let lookupKey = Self.lookupKey(
            for: trimmedWord
        )

        guard !lookupKey.isEmpty else {
            throw WiktionaryClientError.notFound
        }

        let directTitle = trimmedWord.lowercased(
            with: Self.frenchLocale
        )

        var lastLookupError:
            WiktionaryClientError = .notFound

        do {
            return try await definition(
                for: word,
                title: directTitle
            )
        } catch let error as WiktionaryClientError
            where error == .notFound
                || error == .emptyExtract
        {
            lastLookupError = error
        }

        let candidateTitles = try await candidateTitles(
            for: lookupKey,
            excluding: directTitle
        )

        for title in candidateTitles {
            do {
                return try await definition(
                    for: word,
                    title: title
                )
            } catch let error
                as WiktionaryClientError
                where error == .notFound
                    || error == .emptyExtract
            {
                lastLookupError = error
            }
        }

        throw lastLookupError
    }

    private func candidateTitles(
        for lookupKey: String,
        excluding directTitle: String
    ) async throws -> [String] {
        let searchWord = lookupKey.lowercased(
            with: Self.frenchLocale
        )

        let data = try await load(
            queryItems: [
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
                    name: "list",
                    value: "search"
                ),
                URLQueryItem(
                    name: "srsearch",
                    value: "intitle:\(searchWord)"
                ),
                URLQueryItem(
                    name: "srnamespace",
                    value: "0"
                ),
                URLQueryItem(
                    name: "srlimit",
                    value: "10"
                )
            ]
        )

        let apiResponse: SearchAPIResponse

        do {
            apiResponse = try JSONDecoder().decode(
                SearchAPIResponse.self,
                from: data
            )
        } catch {
            throw WiktionaryClientError.invalidData
        }

        var seenTitles = Set([directTitle])
        var matchingTitles: [String] = []

        for result in apiResponse.query.search {
            let title = result.title

            guard
                Self.lookupKey(for: title)
                    == lookupKey,
                seenTitles.insert(title).inserted
            else {
                continue
            }

            matchingTitles.append(title)
        }

        return matchingTitles
            .enumerated()
            .sorted { left, right in
                let leftCost = Self.spellingCost(
                    for: left.element
                )
                let rightCost = Self.spellingCost(
                    for: right.element
                )

                if leftCost != rightCost {
                    return leftCost < rightCost
                }

                let leftIsLowercase =
                    left.element.lowercased(
                        with: Self.frenchLocale
                    ) == left.element
                let rightIsLowercase =
                    right.element.lowercased(
                        with: Self.frenchLocale
                    ) == right.element

                if leftIsLowercase
                    != rightIsLowercase
                {
                    return leftIsLowercase
                }

                return left.offset < right.offset
            }
            .map { $0.element }
    }

    private func definition(
        for word: String,
        title: String
    ) async throws -> WordDefinition {
        let data = try await load(
            queryItems: [
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
                    value: title
                )
            ]
        )

        let apiResponse: DefinitionAPIResponse

        do {
            apiResponse = try JSONDecoder().decode(
                DefinitionAPIResponse.self,
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

    private func load(
        queryItems: [URLQueryItem]
    ) async throws -> Data {

        guard
            var components = URLComponents(
                string:
                    "https://fr.wiktionary.org/w/api.php"
            )
        else {
            throw WiktionaryClientError.invalidURL
        }

        components.queryItems = queryItems

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

        return data
    }

    private static let frenchLocale = Locale(
        identifier: "fr_FR"
    )

    private static func lookupKey(
        for value: String
    ) -> String {
        let expandedLigatures = value
            .replacingOccurrences(
                of: "œ",
                with: "oe"
            )
            .replacingOccurrences(
                of: "Œ",
                with: "OE"
            )
            .replacingOccurrences(
                of: "æ",
                with: "ae"
            )
            .replacingOccurrences(
                of: "Æ",
                with: "AE"
            )

        let folded = expandedLigatures
            .folding(
                options: [.diacriticInsensitive],
                locale: frenchLocale
            )
            .uppercased(with: frenchLocale)

        return String(
            folded.filter { character in
                character >= "A"
                    && character <= "Z"
            }
        )
    }

    private static func spellingCost(
        for value: String
    ) -> Int {
        let ligatureCount = value.filter {
            "œŒæÆ".contains($0)
        }.count

        let accentCount = value
            .decomposedStringWithCanonicalMapping
            .unicodeScalars
            .filter {
                CharacterSet.nonBaseCharacters
                    .contains($0)
            }
            .count

        return ligatureCount + accentCount
    }

    private struct SearchAPIResponse: Decodable {
        let query: SearchQuery
    }

    private struct SearchQuery: Decodable {
        let search: [SearchResult]
    }

    private struct SearchResult: Decodable {
        let title: String
    }

    private struct DefinitionAPIResponse: Decodable {
        let query: DefinitionQuery
    }

    private struct DefinitionQuery: Decodable {
        let pages: [Page]
    }

    private struct Page: Decodable {
        let title: String
        let extract: String?
        let missing: Bool?
    }
}
