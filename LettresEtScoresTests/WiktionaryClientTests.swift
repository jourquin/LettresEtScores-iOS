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
    func rejectsMissingPage() async {
        let json = """
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