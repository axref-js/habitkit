//
//  CreateCommunityView.swift
//  habitkit
//
//  Form to create a new community.
//

import SwiftUI
import SwiftData

struct CreateCommunityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userName") private var userName = ""
    @AppStorage("userBio") private var userBio = ""
    @Query private var allHabits: [Habit]

    @State private var name = ""
    @State private var desc = ""
    @State private var habitFocus = ""
    @State private var selectedEmoji = "🏛️"
    @State private var selectedColor = "8957E5"
    @State private var discordLink = ""
    @State private var redditLink = ""

    private var userStreak: Int { allHabits.map(\.streak).max() ?? 0 }
    private var userRate: Double {
        guard !allHabits.isEmpty else { return 0 }
        return allHabits.reduce(0.0) { $0 + $1.completionRate } / Double(allHabits.count)
    }

    private let emojis = ["🏛️", "🧠", "💪", "🌅", "📚", "🧘", "🏃", "🎯", "🔥", "⚡", "🌿", "🚫", "💎", "🎨", "🎵"]
    private let colors = ["8957E5", "39D353", "F78166", "58A6FF", "FF7B72", "FFA657", "D2A8FF", "3FB950"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Preview card
                    previewCard

                    // Form fields
                    formSection("Community Name") {
                        TextField("e.g. Deep Workers", text: $name)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                    }

                    formSection("Description") {
                        TextField("What's this community about?", text: $desc, axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(3)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                    }

                    formSection("Habit Focus") {
                        TextField("e.g. Deep Work, Meditation, Fitness", text: $habitFocus)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                    }

                    formSection("Discord Link (Optional)") {
                        TextField("e.g. https://discord.gg/...", text: $discordLink)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textPrimary)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                    }

                    formSection("Reddit Link (Optional)") {
                        TextField("e.g. https://reddit.com/r/...", text: $redditLink)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textPrimary)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                    }

                    formSection("Icon") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                        HapticManager.light()
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 24))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(selectedEmoji == emoji ? Color(hex: selectedColor).opacity(0.2) : Theme.surface)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .strokeBorder(selectedEmoji == emoji ? Color(hex: selectedColor) : .clear, lineWidth: 2)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    formSection("Color") {
                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                    HapticManager.light()
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle().strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .shadow(color: selectedColor == color ? Color(hex: color).opacity(0.5) : .clear, radius: 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Create button
                    Button {
                        createCommunity()
                    } label: {
                        Text("Create Community 🚀")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(name.isEmpty ? Theme.textTertiary : Color(hex: selectedColor))
                            )
                    }
                    .disabled(name.isEmpty)
                    .buttonStyle(.plain)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Community")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        HStack(spacing: 12) {
            Text(selectedEmoji)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(Color(hex: selectedColor).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Community Name" : name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(name.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                Text(habitFocus.isEmpty ? "Habit focus" : habitFocus)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("1")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: selectedColor))
                Text("member")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: selectedColor).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func formSection(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)
            content()
        }
    }

    private func createCommunity() {
        let community = Community(
            name: name,
            desc: desc,
            emoji: selectedEmoji,
            accentHex: selectedColor,
            habitFocus: habitFocus,
            creatorName: userName.isEmpty ? "You" : userName,
            discordLink: discordLink,
            redditLink: redditLink
        )
        modelContext.insert(community)

        // Add self as leader
        let me = CommunityMember(
            name: userName.isEmpty ? "Me" : userName,
            bio: userBio,
            avatarEmoji: "⭐",
            isCurrentUser: true,
            isLeader: true,
            streak: userStreak,
            completionRate: userRate,
            badgeCount: 0
        )
        me.community = community
        modelContext.insert(me)

        // Welcome message
        let welcome = CommunityMessage(
            senderName: userName.isEmpty ? "Me" : userName,
            senderEmoji: "⭐",
            text: "Welcome to \(name)! Let's build great habits together. 🚀",
            isCurrentUser: true
        )
        welcome.community = community
        modelContext.insert(welcome)

        HapticManager.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, Community.self, CommunityMember.self, CommunityMessage.self, configurations: config)
    return CreateCommunityView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
