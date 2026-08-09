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
    case invalidUTF8(String)
}

enum WordListLoader {
    // MARK: - Plain-text resources

    static func loadWords(
        named name: String,
        withExtension fileExtension: String = "txt",
        bundle: Bundle = .main
    ) throws -> [String] {
        let resourceName = "\(name).\(fileExtension)"

        guard let url = bundle.url(
            forResource: name,
            withExtension: fileExtension
        ) else {
            throw WordListLoaderError.resourceNotFound(
                resourceName
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
                resourceName
            )
        }

        return words(from: contents)
    }

    // MARK: - Compressed resources

    static func loadWords(
        fromCompressedResourceNamed name: String,
        withExtension fileExtension: String = "deflate",
        bundle: Bundle = .main
    ) throws -> [String] {
        let resourceName = "\(name).\(fileExtension)"

        guard let url = bundle.url(
            forResource: name,
            withExtension: fileExtension
        ) else {
            throw WordListLoaderError.resourceNotFound(
                resourceName
            )
        }

        let compressedData: Data

        do {
            compressedData = try Data(
                contentsOf: url,
                options: .mappedIfSafe
            )
        } catch {
            throw WordListLoaderError.unreadableResource(
                resourceName
            )
        }

        let decompressedData: Data

        do {
            decompressedData = try (
                compressedData as NSData
            ).decompressed(using: .zlib) as Data
        } catch {
            throw WordListLoaderError.unreadableResource(
                resourceName
            )
        }

        guard let contents = String(
            data: decompressedData,
            encoding: .utf8
        ) else {
            throw WordListLoaderError.invalidUTF8(
                resourceName
            )
        }

        return words(from: contents)
    }

    // MARK: - Parsing

    private static func words(
        from contents: String
    ) -> [String] {
        contents
            .split(whereSeparator: { $0.isNewline })
            .map(String.init)
    }
}
