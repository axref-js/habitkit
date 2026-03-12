//
//  LeaderboardView.swift
//  habitkit
//
//  Global leaderboard with Olympic-style podium for top 3.
//

import SwiftUI
import SwiftData

// MARK: - Simulated Global User

struct LeaderboardUser: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let streak: Int
    let totalLogged: Int
    let completionRate: Double
    let badgeCount: Int
    let isCurrentUser: Bool
    let country: String

    var score: Int {
        streak * 10 + totalLogged * 2 + Int(completionRate * 100) + badgeCount * 15
    }
}

// MARK: - View

struct LeaderboardView: View {
    @Query private var allHabits: [Habit]
    @AppStorage("userName") private var userName = ""
    @ObservedObject var proManager = ProManager.shared

    @State private var showingPaywall = false
    @State private var selectedTimeframe: Timeframe = .allTime
    @State private var appeared = false

    enum Timeframe: String, CaseIterable {
        case weekly = "This Week"
        case monthly = "This Month"
        case allTime = "All Time"
    }

    // Current user stats
    private var userStreak: Int { allHabits.map(\.streak).max() ?? 0 }
    private var userTotalLogged: Int { allHabits.flatMap(\.logs).count }
    private var userRate: Double {
        guard !allHabits.isEmpty else { return 0 }
        return allHabits.reduce(0.0) { $0 + $1.completionRate } / Double(allHabits.count)
    }
    private var userBadgeCount: Int {
        var c = 0
        if userTotalLogged >= 1 { c += 1 }
        if userStreak >= 7 { c += 1 }
        if userStreak >= 21 { c += 1 }
        if userTotalLogged >= 50 { c += 1 }
        if userTotalLogged >= 100 { c += 1 }
        if allHabits.filter(\.isActive).count >= 5 { c += 1 }
        return c
    }

    private var allUsers: [LeaderboardUser] {
        var users = simulatedUsers
        users.append(LeaderboardUser(
            name: userName.isEmpty ? "You" : userName,
            emoji: "⭐",
            streak: userStreak,
            totalLogged: userTotalLogged,
            completionRate: userRate,
            badgeCount: userBadgeCount,
            isCurrentUser: true,
            country: "🏠"
        ))
        return users.sorted { $0.score > $1.score }
    }

    private var currentUserRank: Int {
        (allUsers.firstIndex(where: \.isCurrentUser) ?? allUsers.count) + 1
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if proManager.isPro {
                leaderboardContent
            } else {
                lockedView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "FFA657"))
                    Text("Leaderboard")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingPaywall) {
            ProPaywallSheet(highlightedFeature: .globalLeaderboard)
        }
    }

    // MARK: - Locked

    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(hex: "FFA657").opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "FFA657"))
            }
            Text("Global Leaderboard")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Compete with habit builders worldwide.\nUpgrade to Pro to see your ranking.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingPaywall = true
                HapticManager.medium()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Unlock with Pro")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: "FFA657"), Color(hex: "F78166")], startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Leaderboard Content

    private var leaderboardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Timeframe picker
                timeframePicker

                // Your rank card
                yourRankCard

                // Olympic Podium (top 3)
                if allUsers.count >= 3 {
                    olympicPodium
                }

                // Remaining users
                remainingList

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    // MARK: - Timeframe

    private var timeframePicker: some View {
        HStack(spacing: 4) {
            ForEach(Timeframe.allCases, id: \.self) { tf in
                Button {
                    selectedTimeframe = tf
                    HapticManager.light()
                } label: {
                    Text(tf.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedTimeframe == tf ? .white : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selectedTimeframe == tf ? Color(hex: "FFA657") : Theme.surface)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Your Rank

    private var yourRankCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.accent, Color(hex: "8957E5")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Text("⭐")
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Your Ranking")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Text("#\(currentUserRank)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                    Text("of \(allUsers.count)")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(allUsers.first(where: \.isCurrentUser)?.score ?? 0)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                Text("points")
                    .font(Theme.microFont)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.accent.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Olympic Podium

    private var olympicPodium: some View {
        let top3 = Array(allUsers.prefix(3))
        let gold = top3[0]
        let silver = top3[1]
        let bronze = top3[2]

        return VStack(spacing: 0) {
            // Title
            HStack(spacing: 6) {
                Text("🏆")
                    .font(.system(size: 16))
                Text("TOP PERFORMERS")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "FFA657"))
            }
            .padding(.bottom, 20)

            // Podium blocks
            HStack(alignment: .bottom, spacing: 6) {
                // 🥈 Silver — left, shorter
                podiumColumn(
                    user: silver,
                    rank: 2,
                    medal: "🥈",
                    podiumHeight: appeared ? 100 : 0,
                    podiumColor: LinearGradient(
                        colors: [Color(hex: "8B949E"), Color(hex: "6E7681")],
                        startPoint: .top, endPoint: .bottom
                    ),
                    crownColor: Color(hex: "C0C0C0"),
                    glowColor: Color(hex: "C0C0C0")
                )

                // 🥇 Gold — center, tallest
                podiumColumn(
                    user: gold,
                    rank: 1,
                    medal: "🥇",
                    podiumHeight: appeared ? 140 : 0,
                    podiumColor: LinearGradient(
                        colors: [Color(hex: "FFA657"), Color(hex: "F78166")],
                        startPoint: .top, endPoint: .bottom
                    ),
                    crownColor: Color(hex: "FFD700"),
                    glowColor: Color(hex: "FFA657")
                )

                // 🥉 Bronze — right, shortest
                podiumColumn(
                    user: bronze,
                    rank: 3,
                    medal: "🥉",
                    podiumHeight: appeared ? 75 : 0,
                    podiumColor: LinearGradient(
                        colors: [Color(hex: "F78166"), Color(hex: "DA6F3C")],
                        startPoint: .top, endPoint: .bottom
                    ),
                    crownColor: Color(hex: "CD7F32"),
                    glowColor: Color(hex: "F78166")
                )
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.surface)
                .shadow(color: Color(hex: "FFA657").opacity(0.08), radius: 20, y: 6)
        )
    }

    private func podiumColumn(
        user: LeaderboardUser,
        rank: Int,
        medal: String,
        podiumHeight: CGFloat,
        podiumColor: LinearGradient,
        crownColor: Color,
        glowColor: Color
    ) -> some View {
        VStack(spacing: 0) {
            // Crown for #1
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(crownColor)
                    .shadow(color: crownColor.opacity(0.6), radius: 8)
                    .padding(.bottom, 4)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3), value: appeared)
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.surfaceHover)
                    .frame(width: rank == 1 ? 56 : 46, height: rank == 1 ? 56 : 46)
                    .shadow(color: glowColor.opacity(0.3), radius: rank == 1 ? 12 : 6)

                if rank == 1 {
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA657")],
                                          startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 3
                        )
                        .frame(width: 56, height: 56)
                }

                Text(user.emoji)
                    .font(.system(size: rank == 1 ? 26 : 20))
            }

            // Name
            Text(user.isCurrentUser ? "You" : user.name)
                .font(.system(size: rank == 1 ? 13 : 11, weight: .bold))
                .foregroundStyle(user.isCurrentUser ? Theme.accent : Theme.textPrimary)
                .lineLimit(1)
                .padding(.top, 6)

            Text("\(user.country)")
                .font(.system(size: 12))
                .padding(.top, 1)

            // Score
            Text("\(user.score)")
                .font(.system(size: rank == 1 ? 16 : 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 2)

            // Medal
            Text(medal)
                .font(.system(size: rank == 1 ? 28 : 22))
                .padding(.top, 4)

            // Podium block
            RoundedRectangle(cornerRadius: 10)
                .fill(podiumColor)
                .frame(height: podiumHeight)
                .overlay(
                    VStack {
                        Text("\(rank)")
                            .font(.system(size: rank == 1 ? 32 : 24, weight: .black, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                        Spacer()
                    }
                    .padding(.top, 8)
                )
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(Double(rank) * 0.1), value: appeared)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Remaining List

    private var remainingList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RANKINGS")
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)

            ForEach(Array(allUsers.dropFirst(3).enumerated()), id: \.element.id) { idx, user in
                leaderboardRow(user, rank: idx + 4)
            }
        }
    }

    private func leaderboardRow(_ user: LeaderboardUser, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 28)

            Text(user.emoji)
                .font(.system(size: 18))
                .frame(width: 34, height: 34)
                .background(Theme.surfaceHover, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.isCurrentUser ? "You" : user.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(user.isCurrentUser ? Theme.accent : Theme.textPrimary)
                    Text(user.country)
                        .font(.system(size: 11))
                    if user.isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 7, weight: .black, design: .monospaced))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Theme.accent.opacity(0.12)))
                    }
                }
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.system(size: 8)).foregroundStyle(Color(hex: "F78166"))
                        Text("\(user.streak)d").font(.system(size: 10, weight: .medium)).foregroundStyle(Theme.textTertiary)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.square.fill").font(.system(size: 8)).foregroundStyle(Color(hex: "39D353"))
                        Text("\(user.totalLogged)").font(.system(size: 10, weight: .medium)).foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            Spacer()

            Text("\(user.score)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(user.isCurrentUser ? Theme.accent.opacity(0.06) : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(user.isCurrentUser ? Theme.accent.opacity(0.2) : .clear, lineWidth: 1)
                )
        )
    }

    // MARK: - Simulated Users

    private var simulatedUsers: [LeaderboardUser] {
        [
            LeaderboardUser(name: "Kai", emoji: "⚡", streak: 142, totalLogged: 380, completionRate: 0.96, badgeCount: 7, isCurrentUser: false, country: "🇯🇵"),
            LeaderboardUser(name: "Emma", emoji: "🌸", streak: 98, totalLogged: 310, completionRate: 0.93, badgeCount: 6, isCurrentUser: false, country: "🇬🇧"),
            LeaderboardUser(name: "Marco", emoji: "🏋️", streak: 87, totalLogged: 260, completionRate: 0.91, badgeCount: 6, isCurrentUser: false, country: "🇮🇹"),
            LeaderboardUser(name: "Aisha", emoji: "📚", streak: 76, totalLogged: 220, completionRate: 0.89, badgeCount: 5, isCurrentUser: false, country: "🇲🇦"),
            LeaderboardUser(name: "Leo", emoji: "🧑‍💻", streak: 65, totalLogged: 195, completionRate: 0.87, badgeCount: 5, isCurrentUser: false, country: "🇧🇷"),
            LeaderboardUser(name: "Sana", emoji: "🧘", streak: 54, totalLogged: 170, completionRate: 0.84, badgeCount: 4, isCurrentUser: false, country: "🇰🇷"),
            LeaderboardUser(name: "Viktor", emoji: "🏃", streak: 43, totalLogged: 140, completionRate: 0.82, badgeCount: 4, isCurrentUser: false, country: "🇩🇪"),
            LeaderboardUser(name: "Lucia", emoji: "🎨", streak: 38, totalLogged: 120, completionRate: 0.79, badgeCount: 3, isCurrentUser: false, country: "🇪🇸"),
            LeaderboardUser(name: "Omar", emoji: "🌅", streak: 30, totalLogged: 95, completionRate: 0.76, badgeCount: 3, isCurrentUser: false, country: "🇪🇬"),
            LeaderboardUser(name: "Freya", emoji: "🌿", streak: 21, totalLogged: 70, completionRate: 0.72, badgeCount: 2, isCurrentUser: false, country: "🇸🇪"),
            LeaderboardUser(name: "Raj", emoji: "💪", streak: 14, totalLogged: 45, completionRate: 0.68, badgeCount: 2, isCurrentUser: false, country: "🇮🇳"),
            LeaderboardUser(name: "Zara", emoji: "✨", streak: 7, totalLogged: 25, completionRate: 0.60, badgeCount: 1, isCurrentUser: false, country: "🇨🇦"),
        ]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LeaderboardView()
    }
    .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
