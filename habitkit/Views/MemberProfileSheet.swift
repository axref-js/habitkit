//
//  MemberProfileSheet.swift
//  habitkit
//
//  Public profile preview for community members.
//

import SwiftUI

struct MemberProfileSheet: View {
    let member: CommunityMember
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Avatar & Name
                    VStack(spacing: 12) {
                        Text(member.avatarEmoji)
                            .font(.system(size: 56))
                            .frame(width: 88, height: 88)
                            .background(
                                Circle()
                                    .fill(Theme.surfaceHover)
                                    .overlay(
                                        Circle().strokeBorder(
                                            member.isLeader
                                                ? LinearGradient(colors: [Color(hex: "FFA657"), Color(hex: "F78166")], startPoint: .top, endPoint: .bottom)
                                                : LinearGradient(colors: [Theme.border, Theme.border], startPoint: .top, endPoint: .bottom)
                                            , lineWidth: 2.5
                                        )
                                    )
                            )

                        HStack(spacing: 8) {
                            Text(member.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)

                            if member.isLeader {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "FFA657"))
                            }
                        }

                        if !member.bio.isEmpty {
                            Text(member.bio)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        Text("Joined \(member.joinedAt.formatted(.dateTime.month(.abbreviated).day().year()))")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textTertiary)
                    }

                    // Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        memberStat(value: "\(member.streak)", label: "Day\nStreak", icon: "flame.fill", color: "F78166")
                        memberStat(value: "\(Int(member.completionRate * 100))%", label: "Completion\nRate", icon: "chart.bar.fill", color: "58A6FF")
                        memberStat(value: "\(member.badgeCount)", label: "Badges\nEarned", icon: "trophy.fill", color: "FFA657")
                    }

                    // Badges
                    if member.badgeCount > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("EARNED BADGES")
                                .font(Theme.microFont)
                                .foregroundStyle(Theme.textTertiary)

                            HStack(spacing: 8) {
                                // Show badges based on count
                                if member.badgeCount >= 1 { badgePill("🌟", "First Log") }
                                if member.badgeCount >= 2 { badgePill("🔥", "Streak") }
                                if member.badgeCount >= 3 { badgePill("💎", "21 Days") }
                                if member.badgeCount >= 4 { badgePill("⚡", "50 Logs") }
                                if member.badgeCount >= 5 { badgePill("🏆", "100 Logs") }
                                if member.badgeCount >= 6 { badgePill("🎯", "Period") }
                                if member.badgeCount >= 7 { badgePill("🚫", "Quit Champ") }
                            }
                        }
                    }

                    // Motivation
                    VStack(spacing: 10) {
                        Text("ACTIVITY")
                            .font(Theme.microFont)
                            .foregroundStyle(Theme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Image(systemName: member.streak >= 21 ? "sparkles" : member.streak >= 7 ? "bolt.fill" : "leaf.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(member.streak >= 21 ? Color(hex: "FFA657") : member.streak >= 7 ? Color(hex: "58A6FF") : Theme.accent)

                            Text(activityMessage)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private func memberStat(value: String, label: String, icon: String, color: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
    }

    private func badgePill(_ emoji: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(emoji).font(.system(size: 12))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(Theme.surface).overlay(Capsule().strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)))
    }

    private var activityMessage: String {
        if member.streak >= 60 { return "\(member.name) is an absolute machine. \(member.streak) days of consistency. Legendary." }
        if member.streak >= 21 { return "\(member.name) has built a solid habit — \(member.streak) days strong." }
        if member.streak >= 7 { return "\(member.name) is gaining momentum with a \(member.streak)-day streak." }
        return "\(member.name) is just getting started. Show some support! 💪"
    }
}

// MARK: - Preview

#Preview {
    let member = CommunityMember(name: "Alex", bio: "Software engineer. 6 AM club.", avatarEmoji: "🧑‍💻", isLeader: true, streak: 45, completionRate: 0.92, badgeCount: 5)
    return MemberProfileSheet(member: member)
}
