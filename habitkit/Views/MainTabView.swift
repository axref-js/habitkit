//
//  MainTabView.swift
//  habitkit
//
//  Root tab bar: Home / Habits / Communities / Profile.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String {
        case home, habits, communities, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home)

            HabitsView()
                .tabItem {
                    Image(systemName: "square.grid.3x3.fill")
                    Text("Habits")
                }
                .tag(Tab.habits)

            CommunitiesView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Community")
                }
                .tag(Tab.communities)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(Tab.profile)
        }
        .tint(Theme.accent)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.surface)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.textTertiary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.textTertiary)
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.accent)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, HabitLog.self, Community.self, CommunityMember.self, CommunityMessage.self], inMemory: true)
        .preferredColorScheme(.dark)
}
