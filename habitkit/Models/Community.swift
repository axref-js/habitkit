//
//  Community.swift
//  habitkit
//
//  Community models for shared habit progression, chat, and leaderboards.
//

import Foundation
import SwiftData

// MARK: - Community

@Model
final class Community {
    var id: UUID = UUID()
    var name: String = ""
    var desc: String = ""
    var emoji: String = "🏛️"
    var accentHex: String = "8957E5"
    var habitFocus: String = ""         // e.g. "Deep Work", "Fitness"
    var createdAt: Date = Date.now
    var creatorName: String = ""
    var discordLink: String = ""
    var redditLink: String = ""

    @Relationship(deleteRule: .cascade, inverse: \CommunityMember.community)
    var members: [CommunityMember] = []

    @Relationship(deleteRule: .cascade, inverse: \CommunityMessage.community)
    var messages: [CommunityMessage] = []

    var memberCount: Int { members.count }

    init(
        name: String,
        desc: String = "",
        emoji: String = "🏛️",
        accentHex: String = "8957E5",
        habitFocus: String = "",
        creatorName: String = "",
        discordLink: String = "",
        redditLink: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.emoji = emoji
        self.accentHex = accentHex
        self.habitFocus = habitFocus
        self.createdAt = .now
        self.creatorName = creatorName
        self.discordLink = discordLink
        self.redditLink = redditLink
    }
}

// MARK: - Member

@Model
final class CommunityMember {
    var id: UUID = UUID()
    var name: String = ""
    var bio: String = ""
    var avatarEmoji: String = "👤"
    var joinedAt: Date = Date.now
    var isCurrentUser: Bool = false
    var isLeader: Bool = false
    var streak: Int = 0
    var completionRate: Double = 0.0
    var badgeCount: Int = 0

    var community: Community?

    init(
        name: String,
        bio: String = "",
        avatarEmoji: String = "👤",
        isCurrentUser: Bool = false,
        isLeader: Bool = false,
        streak: Int = 0,
        completionRate: Double = 0.0,
        badgeCount: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.bio = bio
        self.avatarEmoji = avatarEmoji
        self.joinedAt = .now
        self.isCurrentUser = isCurrentUser
        self.isLeader = isLeader
        self.streak = streak
        self.completionRate = completionRate
        self.badgeCount = badgeCount
    }
}

// MARK: - Message

@Model
final class CommunityMessage {
    var id: UUID = UUID()
    var senderName: String = ""
    var senderEmoji: String = "👤"
    var text: String = ""
    var timestamp: Date = Date.now
    var isCurrentUser: Bool = false
    /// Motivation reaction emojis
    var reactions: String = ""

    var community: Community?

    init(
        senderName: String,
        senderEmoji: String = "👤",
        text: String,
        isCurrentUser: Bool = false
    ) {
        self.id = UUID()
        self.senderName = senderName
        self.senderEmoji = senderEmoji
        self.text = text
        self.timestamp = .now
        self.isCurrentUser = isCurrentUser
    }
}

// MARK: - Leadership Requirements

enum CommunityRequirement {
    /// Check if user can create a community
    static func canCreate(streak: Int, badgeCount: Int, totalLogged: Int) -> Bool {
        // Need at least 21-day streak OR 3+ badges OR 50+ total logs
        return streak >= 21 || badgeCount >= 3 || totalLogged >= 50
    }

    static var requirements: [(icon: String, label: String, met: (Int, Int, Int) -> Bool)] {
        [
            ("flame.fill", "21-day streak", { s, _, _ in s >= 21 }),
            ("trophy.fill", "3+ badges earned", { _, b, _ in b >= 3 }),
            ("checkmark.seal.fill", "50+ days logged", { _, _, t in t >= 50 }),
        ]
    }

    static var requirementDescription: String {
        "Reach any one milestone to unlock community creation"
    }
}

// MARK: - Demo Communities

enum DemoCommunities {

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Community>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Community 1: Deep Work
        let deepWork = Community(
            name: "Deep Workers",
            desc: "A tribe of focused builders. We do 90-min deep work blocks and hold each other accountable.",
            emoji: "🧠",
            accentHex: "8957E5",
            habitFocus: "Deep Work",
            creatorName: "Alex"
        )
        context.insert(deepWork)
        let m1 = CommunityMember(name: "Alex", bio: "Software engineer. 6 AM club.", avatarEmoji: "🧑‍💻", isLeader: true, streak: 45, completionRate: 0.92, badgeCount: 5)
        let m2 = CommunityMember(name: "Sarah", bio: "Writer & creator", avatarEmoji: "✍️", streak: 22, completionRate: 0.85, badgeCount: 3)
        let m3 = CommunityMember(name: "Marcus", bio: "Day 14 and going strong", avatarEmoji: "💪", streak: 14, completionRate: 0.78, badgeCount: 2)
        m1.community = deepWork
        m2.community = deepWork
        m3.community = deepWork
        context.insert(m1); context.insert(m2); context.insert(m3)

        let msgs1: [(String, String, String)] = [
            ("Alex", "🧑‍💻", "Just finished a 3-hour deep work session. New personal record! 🔥"),
            ("Sarah", "✍️", "That's incredible! I managed 90 min today. Baby steps."),
            ("Marcus", "💪", "Day 14 complete. The resistance is getting weaker 💎"),
            ("Alex", "🧑‍💻", "Keep going Marcus! Day 21 is when it clicks."),
        ]
        for (i, msg) in msgs1.enumerated() {
            let m = CommunityMessage(senderName: msg.0, senderEmoji: msg.1, text: msg.2)
            m.timestamp = Calendar.current.date(byAdding: .minute, value: -(msgs1.count - i) * 30, to: .now) ?? .now
            m.community = deepWork
            context.insert(m)
        }

        // Community 2: Morning Routine
        let morning = Community(
            name: "5 AM Club",
            desc: "Rise before the world. Morning routines that compound into extraordinary lives.",
            emoji: "🌅",
            accentHex: "F78166",
            habitFocus: "Morning Routine",
            creatorName: "Jordan"
        )
        context.insert(morning)
        let m4 = CommunityMember(name: "Jordan", bio: "4:45 AM every day. No excuses.", avatarEmoji: "🌅", isLeader: true, streak: 67, completionRate: 0.95, badgeCount: 7)
        let m5 = CommunityMember(name: "Priya", bio: "Meditation + journaling", avatarEmoji: "🧘", streak: 30, completionRate: 0.88, badgeCount: 4)
        m4.community = morning
        m5.community = morning
        context.insert(m4); context.insert(m5)

        let msgs2: [(String, String, String)] = [
            ("Jordan", "🌅", "4:47 AM check-in. Cold shower done, journaling now. ❄️"),
            ("Priya", "🧘", "5:10 AM. Meditation complete. Feeling centered. 🙏"),
            ("Jordan", "🌅", "Love it Priya! Consistency is everything."),
        ]
        for (i, msg) in msgs2.enumerated() {
            let m = CommunityMessage(senderName: msg.0, senderEmoji: msg.1, text: msg.2)
            m.timestamp = Calendar.current.date(byAdding: .hour, value: -(msgs2.count - i) * 2, to: .now) ?? .now
            m.community = morning
            context.insert(m)
        }

        // Community 3: Quit Together
        let quit = Community(
            name: "Quit Together",
            desc: "Breaking bad habits as a team. No shame, just progress.",
            emoji: "🚫",
            accentHex: "FF7B72",
            habitFocus: "Quit Habits",
            creatorName: "Riley"
        )
        context.insert(quit)
        let m6 = CommunityMember(name: "Riley", bio: "90 days no sugar 🎉", avatarEmoji: "🚫", isLeader: true, streak: 90, completionRate: 0.90, badgeCount: 6)
        let m7 = CommunityMember(name: "Dev", bio: "2 weeks social media free", avatarEmoji: "📵", streak: 14, completionRate: 0.70, badgeCount: 2)
        m6.community = quit
        m7.community = quit
        context.insert(m6); context.insert(m7)
    }
}
