//
//  Candidate.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 07/08/2026.
//

struct Candidate: Equatable, Sendable {
    let word: String
    let length: Int
    let score: Int

    init(word: String, score: Int) {
        self.word = word
        self.length = word.count
        self.score = score
    }
}
