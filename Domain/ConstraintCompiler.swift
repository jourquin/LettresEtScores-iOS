//
//  ConstraintCompiler.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

import Foundation

enum ConstraintError: Error, Equatable {
    case invalidRegularExpression(String)
}

enum ConstraintCompiler {
    static func compile(
        _ raw: String
    ) throws -> [NSRegularExpression] {
        try raw
            .split(
                separator: ";",
                omittingEmptySubsequences: false
            )
            .compactMap { substring in
                let pattern = String(substring)
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                guard !pattern.isEmpty else {
                    return nil
                }

                do {
                    return try NSRegularExpression(
                        pattern: pattern,
                        options: [.caseInsensitive]
                    )
                } catch {
                    throw ConstraintError
                        .invalidRegularExpression(pattern)
                }
            }
    }

    static func matchesAll(
        _ word: String,
        constraints: [NSRegularExpression]
    ) -> Bool {
        let range = NSRange(
            word.startIndex..<word.endIndex,
            in: word
        )

        return constraints.allSatisfy { constraint in
            constraint.firstMatch(
                in: word,
                options: [],
                range: range
            ) != nil
        }
    }
}
