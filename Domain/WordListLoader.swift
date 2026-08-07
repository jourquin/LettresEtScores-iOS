//
//  WordListLoader.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation

enum WordListLoaderError: Error, Equatable {
    case resourceNotFound(String)
    case unreadableResource(String)
}

enum WordListLoader {
    static func loadWords(
        named name: String,
        withExtension fileExtension: String = "txt",
        bundle: Bundle = .main
    ) throws -> [String] {
        guard let url = bundle.url(
            forResource: name,
            withExtension: fileExtension
        ) else {
            throw WordListLoaderError.resourceNotFound(
                "\(name).\(fileExtension)"
            )
        }

        let contents: String

        do {
            contents = try String(
                contentsOf: url,
                encoding: .utf8
            )
        } catch {
            throw WordListLoaderError.unreadableResource(
                url.lastPathComponent
            )
        }

        return contents
            .split(whereSeparator: { $0.isNewline })
            .map(String.init)
    }
}

extension WordFinder {
    init(
        resource name: String,
        withExtension fileExtension: String = "txt",
        bundle: Bundle = .main
    ) throws {
        let words = try WordListLoader.loadWords(
            named: name,
            withExtension: fileExtension,
            bundle: bundle
        )

        try self.init(words: words)
    }
}
