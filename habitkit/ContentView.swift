//
//  ContentView.swift
//  habitkit
//
//  Root view — orchestrates splash → onboarding → main app.
//

import SwiftUI
import SwiftData

enum AppPhase {
    case splash
    case onboarding
    case main
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var authManager = AuthManager.shared

    @State private var phase: AppPhase = .splash

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch phase {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = hasCompletedOnboarding ? .main : .onboarding
                    }
                }
                .transition(.opacity)

            case .onboarding:
                OnboardingView {
                    hasCompletedOnboarding = true
                    StarterPack.seedIfNeeded(context: modelContext)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = .main
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .main:
                if authManager.isAuthenticated {
                    MainTabView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .onAppear {
                            StarterPack.seedIfNeeded(context: modelContext)
                        }
                } else {
                    LoginView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("First Launch") {
    ContentView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}

#Preview("Returning User") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    StarterPack.seedIfNeeded(context: container.mainContext)

    return ContentView()
        .modelContainer(container)
        .onAppear {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
}
