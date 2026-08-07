//
//  SearchResults.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//
struct SearchResult: Equatable, Sendable {
    let longest: [Candidate]
    let highestScoring: [Candidate]
    let possibleCount: Int
    let normalizedLetters: String
    let jokerCount: Int
}
