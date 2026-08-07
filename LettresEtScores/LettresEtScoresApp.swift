//
//  LettresEtScoresApp.swift
//  LettresEtScores
//
//  Created by Bart Jourquin on 06/08/2026.
//

import SwiftUI

@main
struct LettresEtScoresApp: App {
    @StateObject private var wordFinderStore =
        WordFinderStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: wordFinderStore)
        }
    }
}
