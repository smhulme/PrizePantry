//
//  prizepantryApp.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/29/25.
//

import SwiftUI
import SwiftData

@main
struct prizepantryApp: App {
    var sharedModelContainer: ModelContainer = {
        // Change 'Item.self' to 'Child.self' here
        let schema = Schema([
            Child.self,
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
        }
        .modelContainer(sharedModelContainer)
    }
}
