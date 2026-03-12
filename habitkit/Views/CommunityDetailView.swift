//
//  CommunityDetailView.swift
//  habitkit
//
//  Community detail: leaderboard, chat, join/leave, member profiles.
//

import SwiftUI
import SwiftData

struct CommunityDetailView: View {
    @Bindable var community: Community
    @Environment(\.modelContext) private var modelContext

    @AppStorage("userName") private var userName = ""
    @AppStorage("userBio") private var userBio = ""

    @Query private var allHabits: [Habit]

    @State private var selectedTab: DetailTab = .chat
    @State private var messageText = ""
    @State private var selectedMember: CommunityMember?

    private var isMember: Bool { community.members.contains(where: \.isCurrentUser) }
    private var sortedMembers: [CommunityMember] { community.members.sorted { $0.streak > $1.streak } }
    private var sortedMessages: [CommunityMessage] { community.messages.sorted { $0.timestamp < $1.timestamp } }
    private var userStreak: Int { allHabits.map(\.streak).max() ?? 0 }
    private var userRate: Double {
        guard !allHabits.isEmpty else { return 0 }
        return allHabits.reduce(0.0) { $0 + $1.completionRate } / Double(allHabits.count)
    }
    private var totalLogged: Int { allHabits.flatMap(\.logs).count }
    private var userBadgeCount: Int {
        var c = 0
        if totalLogged >= 1 { c += 1 }
        if userStreak >= 7 { c += 1 }
        if userStreak >= 21 { c += 1 }
        if totalLogged >= 50 { c += 1 }
        if totalLogged >= 100 { c += 1 }
        return c
    }

    enum DetailTab: String, CaseIterable {
        case chat = "Chat"
        case leaderboard = "Leaderboard"
        case members = "Members"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            communityHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Tab picker
            tabPicker
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Content
            switch selectedTab {
            case .chat: chatView
            case .leaderboard: leaderboardView
            case .members: membersView
            }
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(community.emoji).font(.system(size: 16))
                    Text(community.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedMember) { member in
            MemberProfileSheet(member: member)
        }
    }

    // MARK: - Header

    private var communityHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Text(community.emoji)
                    .font(.system(size: 36))
                    .frame(width: 56, height: 56)
                    .background(Color(hex: community.accentHex).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(community.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    HStack(spacing: 12) {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(community.memberCount)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(Color(hex: community.accentHex))

                        HStack(spacing: 3) {
                            Image(systemName: "target")
                                .font(.system(size: 10))
                            Text(community.habitFocus)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()
            }

            Text(community.desc)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)

            // External Links
            if !community.discordLink.isEmpty || !community.redditLink.isEmpty {
                HStack(spacing: 12) {
                    if !community.discordLink.isEmpty {
                        Link(destination: URL(string: community.discordLink)!) {
                            HStack(spacing: 4) {
                                Image(systemName: "message.fill") // Using a generic icon for Discord as there isn't a native one
                                Text("Discord")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "5865F2"), in: Capsule())
                        }
                    }
                    if !community.redditLink.isEmpty {
                        Link(destination: URL(string: community.redditLink)!) {
                            HStack(spacing: 4) {
                                Image(systemName: "r.square.fill") // Generic icon for Reddit
                                Text("Reddit")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "FF4500"), in: Capsule())
                        }
                    }
                }
                .padding(.top, 4)
            }

            // Join / Leave
            if isMember {
                Button {
                    leaveCommunity()
                } label: {
                    Text("Leave Community")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF7B72"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: "FF7B72").opacity(0.1))
                                .overlay(Capsule().strokeBorder(Color(hex: "FF7B72").opacity(0.3), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    joinCommunity()
                } label: {
                    Text("Join Community 🤝")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: community.accentHex), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                    HapticManager.light()
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? .white : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color(hex: community.accentHex) : Theme.surface)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(sortedMessages) { message in
                            chatBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onAppear {
                    if let last = sortedMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            // Input bar
            if isMember {
                chatInputBar
            } else {
                joinToChat
            }
        }
    }

    private func chatBubble(_ message: CommunityMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isCurrentUser {
                Text(message.senderEmoji)
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
                    .background(Theme.surfaceHover, in: Circle())
            }

            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !message.isCurrentUser {
                    Text(message.senderName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: community.accentHex))
                }

                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundStyle(message.isCurrentUser ? .white : Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isCurrentUser ? Color(hex: community.accentHex) : Theme.surface)
                    )

                Text(timeAgo(message.timestamp))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: message.isCurrentUser ? .trailing : .leading)

            if message.isCurrentUser {
                Text("🫵")
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
                    .background(Color(hex: community.accentHex).opacity(0.15), in: Circle())
            }
        }
    }

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("Send a message...", text: $messageText)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surface))

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(messageText.isEmpty ? Theme.textTertiary : Color(hex: community.accentHex))
            }
            .buttonStyle(.plain)
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface.opacity(0.5))
    }

    private var joinToChat: some View {
        HStack {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
            Text("Join to start chatting")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface)
    }

    // MARK: - Leaderboard

    private var leaderboardView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { idx, member in
                    leaderboardRow(member, rank: idx + 1)
                }
            }
            .padding(16)
        }
    }

    private func leaderboardRow(_ member: CommunityMember, rank: Int) -> some View {
        Button {
            selectedMember = member
            HapticManager.light()
        } label: {
            HStack(spacing: 12) {
                // Rank
                ZStack {
                    if rank <= 3 {
                        Circle()
                            .fill(rank == 1 ? Color(hex: "FFA657") : rank == 2 ? Color(hex: "8B949E") : Color(hex: "F78166"))
                            .frame(width: 28, height: 28)
                        Text(rank == 1 ? "🥇" : rank == 2 ? "🥈" : "🥉")
                            .font(.system(size: 14))
                    } else {
                        Circle()
                            .fill(Theme.surfaceHover)
                            .frame(width: 28, height: 28)
                        Text("\(rank)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                // Avatar
                Text(member.avatarEmoji)
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
                    .background(Theme.surfaceHover, in: Circle())

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(member.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if member.isLeader {
                            Text("LEADER")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundStyle(Color(hex: "FFA657"))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color(hex: "FFA657").opacity(0.12)))
                        }
                        if member.isCurrentUser {
                            Text("YOU")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Theme.accent.opacity(0.12)))
                        }
                    }
                    Text("\(Int(member.completionRate * 100))% completion")
                        .font(Theme.microFont)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                // Streak
                VStack(spacing: 0) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: community.accentHex))
                        Text("\(member.streak)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text("streak")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(rank <= 3 ? Color(hex: community.accentHex).opacity(0.04) : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(rank == 1 ? Color(hex: "FFA657").opacity(0.3) : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Members

    private var membersView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(community.members) { member in
                    Button {
                        selectedMember = member
                        HapticManager.light()
                    } label: {
                        HStack(spacing: 12) {
                            Text(member.avatarEmoji)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(Theme.surfaceHover, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(member.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    if member.isLeader {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color(hex: "FFA657"))
                                    }
                                }
                                if !member.bio.isEmpty {
                                    Text(member.bio)
                                        .font(Theme.captionFont)
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("🔥\(member.streak)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Theme.textSecondary)
                                Text("\(member.badgeCount) badges")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Theme.textTertiary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private func joinCommunity() {
        let me = CommunityMember(
            name: userName.isEmpty ? "Me" : userName,
            bio: userBio,
            avatarEmoji: "⭐",
            isCurrentUser: true,
            streak: userStreak,
            completionRate: userRate,
            badgeCount: userBadgeCount
        )
        me.community = community
        modelContext.insert(me)

        // Welcome message
        let welcome = CommunityMessage(
            senderName: community.creatorName,
            senderEmoji: community.emoji,
            text: "Welcome \(me.name)! 🎉 Glad to have you here."
        )
        welcome.community = community
        modelContext.insert(welcome)

        HapticManager.success()
    }

    private func leaveCommunity() {
        if let me = community.members.first(where: \.isCurrentUser) {
            modelContext.delete(me)
            HapticManager.warning()
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let msg = CommunityMessage(
            senderName: userName.isEmpty ? "Me" : userName,
            senderEmoji: "⭐",
            text: messageText,
            isCurrentUser: true
        )
        msg.community = community
        modelContext.insert(msg)
        messageText = ""
        HapticManager.light()
    }

    private func timeAgo(_ date: Date) -> String {
        let diff = Date.now.timeIntervalSince(date)
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, Community.self, CommunityMember.self, CommunityMessage.self, configurations: config)
    DemoCommunities.seedIfNeeded(context: container.mainContext)
    let descriptor = FetchDescriptor<Community>()
    let community = try! container.mainContext.fetch(descriptor).first!
    return NavigationStack {
        CommunityDetailView(community: community)
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
