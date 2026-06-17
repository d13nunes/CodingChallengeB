//
//  CodingChallengeBApp.swift
//  CodingChallengeB
//
//  Created by Diogo Nunes on 17/06/2026.
//

import SwiftData
import SwiftUI

@main
struct CodingChallengeBApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            EmojiEntity.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [EmojiEntity.self])
        }
        .modelContainer(sharedModelContainer)
    }
}
