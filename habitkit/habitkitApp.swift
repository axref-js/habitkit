//
//  habitkitApp.swift
//  habitkit
//
//  App entry point with SwiftData container for Habit + HabitLog.
//

import SwiftUI
import SwiftData
#if canImport(RevenueCat)
import RevenueCat
#endif

@main
struct habitkitApp: App {
    init() {
        #if canImport(RevenueCat)
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "test_tTnzhSVFqMrsYvfQeSuqDNiCiAe")
        #endif
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitLog.self,
            Community.self,
            CommunityMember.self,
            CommunityMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed during development — nuke old store and retry
            let url = modelConfiguration.url
            let storePaths = [
                url.path(),
                url.path() + "-wal",
                url.path() + "-shm",
            ]
            for path in storePaths {
                try? FileManager.default.removeItem(atPath: path)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // Last resort: fall back to an in-memory store so the app never crashes
                print("⚠️ Could not create ModelContainer after reset: \(error). Falling back to in-memory store.")
                let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [fallback])
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
