//
//  WiktionaryClientTests.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//


import Foundation
import Testing
@testable import LettresEtScores

@MainActor
struct WiktionaryClientTests {
    @Test
    func loadsDefinition() async throws {
        let json = """
        {
          "query": {
            "pages": [
              {
                "pageid": 1,
                "ns": 0,
                "title": "chat",
                "extract": "Animal domestique."
              }
            ]
          }
        }
        """

        let client = WiktionaryClient { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (
                Data(json.utf8),
                response
            )
        }

        let definition = try await client
            .definition(for: "CHAT")

        #expect(definition.word == "CHAT")
        #expect(
            definition.extract ==
            "Animal domestique."
        )
        #expect(
            definition.sourceURL.absoluteString ==
            "https://fr.wiktionary.org/wiki/chat"
        )
    }

    @Test
    func loadsDefinitionsWithAccentedTitles()
        async throws
    {
        let examples = [
            (
                word: "EGOUT",
                title: "égout",
                variant: "égoût"
            ),
            (
                word: "EGOUTS",
                title: "égouts",
                variant: "égoûts"
            )
        ]

        for example in examples {
            let client = WiktionaryClient { request in
                let requestedTitle = queryValue(
                    named: "titles",
                    in: request
                )

                let json: String

                if queryValue(
                    named: "list",
                    in: request
                ) == "search" {
                    guard queryValue(
                        named: "srsearch",
                        in: request
                    ) == "intitle:\(example.word.lowercased())"
                    else {
                        throw WiktionaryClientTestError
                            .unexpectedRequest
                    }

                    json = """
                    {
                      "query": {
                        "search": [
                          {
                            "title": "\(example.variant)"
                          },
                          {
                            "title": "\(example.title)"
                          }
                        ]
                      }
                    }
                    """
                } else if requestedTitle
                    == example.word.lowercased()
                {
                    json = """
                    {
                      "query": {
                        "pages": [
                          {
                            "ns": 0,
                            "title": "\(example.word.lowercased())",
                            "missing": true
                          }
                        ]
                      }
                    }
                    """
                } else if requestedTitle
                    == example.title
                {
                    json = """
                    {
                      "query": {
                        "pages": [
                          {
                            "pageid": 1,
                            "ns": 0,
                            "title": "\(example.title)",
                            "extract": "Définition trouvée."
                          }
                        ]
                      }
                    }
                    """
                } else {
                    throw WiktionaryClientTestError
                        .unexpectedRequest
                }

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!

                return (
                    Data(json.utf8),
                    response
                )
            }

            let definition = try await client
                .definition(for: example.word)

            #expect(definition.word == example.word)
            #expect(
                definition.extract
                    == "Définition trouvée."
            )
            #expect(
                definition.sourceURL.lastPathComponent
                    == example.title
            )
        }
    }

    @Test
    func rejectsMissingPage() async {
        let client = WiktionaryClient { request in
            let json: String

            if queryValue(
                named: "list",
                in: request
            ) == "search" {
                json = """
                {
                  "query": {
                    "search": []
                  }
                }
                """
            } else {
                json = """
                {
                  "query": {
                    "pages": [
                      {
                        "ns": 0,
                        "title": "introuvable",
                        "missing": true
                      }
                    ]
                  }
                }
                """
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (
                Data(json.utf8),
                response
            )
        }

        do {
            _ = try await client.definition(
                for: "INTROUVABLE"
            )

            Issue.record(
                "Une erreur était attendue."
            )
        } catch let error
            as WiktionaryClientError
        {
            #expect(error == .notFound)
        } catch {
            Issue.record(
                "Type d’erreur inattendu."
            )
        }
    }

    @Test
    func rejectsHTTPFailure() async {
        let client = WiktionaryClient { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!

            return (
                Data(),
                response
            )
        }

        do {
            _ = try await client.definition(
                for: "CHAT"
            )

            Issue.record(
                "Une erreur était attendue."
            )
        } catch let error
            as WiktionaryClientError
        {
            #expect(error == .httpStatus(503))
        } catch {
            Issue.record(
                "Type d’erreur inattendu."
            )
        }
    }
}

private enum WiktionaryClientTestError: Error {
    case unexpectedRequest
}

private func queryValue(
    named name: String,
    in request: URLRequest
) -> String? {
    guard let url = request.url else {
        return nil
    }

    return URLComponents(
        url: url,
        resolvingAgainstBaseURL: false
    )?
    .queryItems?
    .first { $0.name == name }?
    .value
}
