//
//  CommunitiesView.swift
//  habitkit
//
//  Browse, join, and create habit communities.
//

import SwiftUI
import SwiftData

struct CommunitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Community.createdAt, order: .reverse) private var communities: [Community]
    @Query private var allHabits: [Habit]

    @AppStorage("userName") private var userName = ""
    @AppStorage("userBio") private var userBio = ""
    @AppStorage("hasSeenCommunitiesTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false

    @ObservedObject private var proManager = ProManager.shared
    @State private var showingPaywall = false

    @State private var showingCreateSheet = false
    @State private var showingRequirementsAlert = false

    // User stats for requirement checking
    private var longestStreak: Int { allHabits.map(\.streak).max() ?? 0 }
    private var totalLogged: Int { allHabits.flatMap(\.logs).count }
    private var badgeCount: Int {
        var count = 0
        if totalLogged >= 1 { count += 1 }
        if longestStreak >= 7 { count += 1 }
        if longestStreak >= 21 { count += 1 }
        if totalLogged >= 50 { count += 1 }
        if totalLogged >= 100 { count += 1 }
        if allHabits.filter({ $0.status == .completed }).count >= 1 { count += 1 }
        if allHabits.filter(\.isActive).count >= 5 { count += 1 }
        return count
    }

    private var canCreateCommunity: Bool {
        CommunityRequirement.canCreate(streak: longestStreak, badgeCount: badgeCount, totalLogged: totalLogged)
    }

    private var joinedCommunities: [Community] {
        communities.filter { community in
            community.members.contains(where: \.isCurrentUser)
        }
    }

    private var discoverCommunities: [Community] {
        communities.filter { community in
            !community.members.contains(where: \.isCurrentUser)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Create button
                    createBanner

                    // My Communities
                    if !joinedCommunities.isEmpty {
                        sectionView("My Communities", icon: "person.2.fill") {
                            ForEach(joinedCommunities) { community in
                                NavigationLink(destination: CommunityDetailView(community: community)) {
                                    communityCard(community, joined: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Discover
                    sectionView("Discover", icon: "sparkle.magnifyingglass") {
                        if discoverCommunities.isEmpty && joinedCommunities.isEmpty {
                            emptyState
                        } else {
                            ForEach(discoverCommunities) { community in
                                NavigationLink(destination: CommunityDetailView(community: community)) {
                                    communityCard(community, joined: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.accent)
                        Text("Communities")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingCreateSheet) {
                CreateCommunityView()
            }
            .sheet(isPresented: $showingPaywall) {
                ProPaywallSheet(highlightedFeature: .createCommunity)
            }
            .overlay {
                if showTutorial {
                    TutorialOverlay(pageName: "communities", tips: Tutorials.communities) {
                        showTutorial = false
                        hasSeenTutorial = true
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                DemoCommunities.seedIfNeeded(context: modelContext)
                if !hasSeenTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation { showTutorial = true }
                    }
                }
            }
        }
    }

    // MARK: - Create Banner

    private var createBanner: some View {
        Button {
            if proManager.requirePro(.createCommunity, action: {
                if canCreateCommunity {
                    showingCreateSheet = true
                    HapticManager.medium()
                } else {
                    showingRequirementsAlert = true
                    HapticManager.warning()
                }
            }) == false {
                showingPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Theme.accent, Color(hex: "8957E5")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: canCreateCommunity ? "plus" : "lock.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Create a Community")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        if proManager.isLocked(.createCommunity) {
                            ProBadge(small: true)
                        }
                    }
                    Text(canCreateCommunity ? "Lead others on the same journey" : "Reach milestones to unlock")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(colors: [Theme.accent.opacity(0.3), Color(hex: "8957E5").opacity(0.2)],
                                              startPoint: .leading, endPoint: .trailing),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .alert("Requirements Not Met", isPresented: $showingRequirementsAlert) {
            Button("Got it") {}
        } message: {
            Text("To create a community, you need at least one:\n\n🔥 21-day streak\n🏆 3 badges earned\n✅ 50 days logged\n\nKeep building habits — you're almost there!")
        }
    }

    // MARK: - Community Card

    private func communityCard(_ community: Community, joined: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(community.emoji)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: community.accentHex).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(community.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)

                        if joined {
                            Text("JOINED")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Theme.accent.opacity(0.12)))
                        }
                    }

                    Text(community.desc)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Stats row
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: community.accentHex))
                    Text("\(community.memberCount)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                    Text("members")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: community.accentHex))
                    Text(community.habitFocus)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                if !joined {
                    Text("Join →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: community.accentHex))
                }
            }

            // Member avatars
            HStack(spacing: -6) {
                ForEach(community.members.prefix(5)) { member in
                    Text(member.avatarEmoji)
                        .font(.system(size: 14))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Theme.surface).overlay(Circle().strokeBorder(Theme.border, lineWidth: 1)))
                }
                if community.memberCount > 5 {
                    Text("+\(community.memberCount - 5)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Theme.surfaceHover))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        )
    }

    // MARK: - Helpers

    private func sectionView(_ title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            content()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textTertiary)
            Text("No communities yet")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)
            Text("Be the first to create one and start motivating others!")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, Community.self, CommunityMember.self, CommunityMessage.self, configurations: config)
    StarterPack.seedIfNeeded(context: container.mainContext)
    return CommunitiesView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
