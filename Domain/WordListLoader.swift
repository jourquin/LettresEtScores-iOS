//
//  WordListLoader.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation
import ZIPFoundation

enum WordListLoaderError: Error, Equatable {
    case resourceNotFound(String)
    case unreadableResource(String)
    case archiveEntryNotFound(
        entry: String,
        archive: String
    )
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

    // MARK: - ZIP resources

    static func loadWords(
        fromArchiveNamed archiveName: String,
        withExtension archiveExtension: String = "zip",
        entryNamed entryName: String,
        bundle: Bundle = .main
    ) throws -> [String] {
        let resourceName =
            "\(archiveName).\(archiveExtension)"

        guard let archiveURL = bundle.url(
            forResource: archiveName,
            withExtension: archiveExtension
        ) else {
            throw WordListLoaderError.resourceNotFound(
                resourceName
            )
        }

        let archive: Archive

        do {
            archive = try Archive(
                url: archiveURL,
                accessMode: .read
            )
        } catch {
            throw WordListLoaderError.unreadableResource(
                resourceName
            )
        }

        guard let entry = archive[entryName],
              entry.type == .file
        else {
            throw WordListLoaderError.archiveEntryNotFound(
                entry: entryName,
                archive: resourceName
            )
        }

        var data = Data()

        if entry.uncompressedSize <= UInt64(Int.max) {
            data.reserveCapacity(
                Int(entry.uncompressedSize)
            )
        }

        do {
            let checksum = try archive.extract(
                entry,
                bufferSize: 64 * 1024
            ) { chunk in
                data.append(chunk)
            }

            // La lecture par closure retourne le CRC calculé.
            // Nous le comparons à celui enregistré dans l’archive.
            guard checksum == entry.checksum else {
                throw WordListLoaderError
                    .unreadableResource(resourceName)
            }
        } catch let loaderError as WordListLoaderError {
            throw loaderError
        } catch {
            throw WordListLoaderError.unreadableResource(
                resourceName
            )
        }

        guard let contents = String(
            data: data,
            encoding: .utf8
        ) else {
            throw WordListLoaderError.invalidUTF8(
                entryName
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

// MARK: - WordFinder initializers

extension WordFinder {
    /// Conserve la compatibilité avec les ressources `.txt`.
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

    /// Initialise le moteur depuis une liste placée dans une archive ZIP.
    init(
        archiveResource name: String,
        entryName: String = "ods9.txt",
        bundle: Bundle = .main
    ) throws {
        let words = try WordListLoader.loadWords(
            fromArchiveNamed: name,
            entryNamed: entryName,
            bundle: bundle
        )

        try self.init(words: words)
    }
}
