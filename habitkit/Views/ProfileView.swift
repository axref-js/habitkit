//
//  ProfileView.swift
//  habitkit
//
//  User profile with photo, bio, earned badges, stats, data export, and settings.
//

import SwiftUI
import SwiftData
import PhotosUI
#if canImport(RevenueCat)
import RevenueCat
#endif
#if canImport(RevenueCatUI)
import RevenueCatUI
#endif

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [Habit]

    @AppStorage("userName") private var userName = ""
    @AppStorage("userBio") private var userBio = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("hasSeenProfileTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false

    @ObservedObject private var proManager = ProManager.shared
    @State private var showingPaywall = false
    @State private var paywallFeature: ProFeature?
    
    @ObservedObject private var authManager = AuthManager.shared

    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var isEditingBio = false
    @State private var editedBio = ""
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingCustomerCenter = false

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var showingPhotoPicker = false

    // Stats
    private var totalLogged: Int { allHabits.flatMap(\.logs).count }
    private var activeCount: Int { allHabits.filter(\.isActive).count }
    private var completedCount: Int { allHabits.filter { $0.status == .completed }.count }
    private var quitCount: Int { allHabits.filter(\.isQuitHabit).count }
    private var longestStreak: Int { allHabits.map(\.streak).max() ?? 0 }

    private var overallRate: Double {
        guard !allHabits.isEmpty else { return 0 }
        return allHabits.reduce(0.0) { $0 + $1.completionRate } / Double(allHabits.count)
    }

    private var memberSince: String {
        let earliest = allHabits.map(\.createdAt).min() ?? .now
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: earliest)
    }

    // Profile image file URL
    private var profileImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    profileHeader
                    earnedBadgesSection
                    statsSection
                    habitBreakdownSection
                    settingsSection
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingPaywall) {
                ProPaywallSheet(highlightedFeature: paywallFeature)
            }
            .overlay {
                if showTutorial {
                    TutorialOverlay(pageName: "profile", tips: Tutorials.profile) {
                        showTutorial = false
                        hasSeenTutorial = true
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                loadProfileImage()
                if !hasSeenTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation { showTutorial = true }
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profileImageData = data
                        saveProfileImage(data)
                    }
                }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Photo
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let data = profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Theme.accent.opacity(0.3), lineWidth: 2))
                    } else {
                        // Default gradient avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Theme.accent, Color(hex: "8957E5")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 96, height: 96)
                            Text(avatarInitial)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    // Camera badge
                    ZStack {
                        Circle()
                            .fill(Theme.surface)
                            .frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)

            // Name
            if isEditingName {
                HStack {
                    TextField("Your name", text: $editedName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                        .frame(maxWidth: 220)
                    Button {
                        userName = editedName
                        isEditingName = false
                        HapticManager.light()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.accent)
                    }
                }
            } else {
                Button {
                    editedName = userName
                    isEditingName = true
                } label: {
                    HStack(spacing: 6) {
                        Text(userName.isEmpty ? "Set your name" : userName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Bio
            if isEditingBio {
                VStack(spacing: 8) {
                    TextField("Write something about yourself...", text: $editedBio, axis: .vertical)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(3)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.accent.opacity(0.3), lineWidth: 1))
                        )
                        .frame(maxWidth: 280)

                    Button {
                        userBio = editedBio
                        isEditingBio = false
                        HapticManager.light()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Theme.accent))
                    }
                }
            } else {
                Button {
                    editedBio = userBio
                    isEditingBio = true
                } label: {
                    if userBio.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 12))
                            Text("Add bio")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.surface).overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1)))
                    } else {
                        HStack(spacing: 4) {
                            Text(userBio)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Member since
            Text("Member since \(memberSince)")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.top, 12)
    }

    private var avatarInitial: String {
        let initial = String(userName.prefix(1)).uppercased()
        return initial.isEmpty ? "?" : initial
    }

    // MARK: - Earned Badges (prominent)

    private var allBadges: [(emoji: String, label: String, description: String, unlocked: Bool)] {
        [
            ("🌟", "First Log", "Log your first habit day", totalLogged >= 1),
            ("🔥", "7-Day Streak", "Achieve a 7-day streak", longestStreak >= 7),
            ("💎", "21-Day Streak", "The habit is forming!", longestStreak >= 21),
            ("⚡", "50 Logs", "Half a century of effort", totalLogged >= 50),
            ("🏆", "100 Logs", "Triple-digit dedication", totalLogged >= 100),
            ("🎯", "Period Done", "Complete a habit period", completedCount >= 1),
            ("🚫", "Quit Champion", "30 days without relapse", allHabits.contains { $0.isQuitHabit && $0.daysSinceRelapse >= 30 }),
            ("📊", "Data Nerd", "Export your data", false), // unlocked manually
            ("🌈", "5 Active", "Track 5 habits at once", activeCount >= 5),
            ("⭐", "Perfectionist", "100% week completion", allHabits.contains { $0.weeklyRate >= 1.0 }),
        ]
    }

    private var earnedBadges: [(emoji: String, label: String, description: String, unlocked: Bool)] {
        allBadges.filter(\.unlocked)
    }

    private var lockedBadges: [(emoji: String, label: String, description: String, unlocked: Bool)] {
        allBadges.filter { !$0.unlocked }
    }

    private var earnedBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BADGES")
                    .font(Theme.microFont)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(earnedBadges.count)/\(allBadges.count) earned")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
            }

            // Earned
            if !earnedBadges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(earnedBadges, id: \.label) { badge in
                            earnedBadgeCard(badge.emoji, badge.label, badge.description)
                        }
                    }
                }
            }

            // Locked (dimmed, compact)
            if !lockedBadges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(lockedBadges, id: \.label) { badge in
                            lockedBadgeChip(badge.emoji, badge.label)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func earnedBadgeCard(_ emoji: String, _ label: String, _ description: String) -> some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 32))
                .shadow(color: Theme.accent.opacity(0.3), radius: 8)

            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            Text(description)
                .font(.system(size: 9))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 100)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(colors: [Theme.accent.opacity(0.4), Color(hex: "8957E5").opacity(0.3)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Theme.accent.opacity(0.1), radius: 8)
        )
    }

    private func lockedBadgeChip(_ emoji: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 20))
                .grayscale(1)
                .opacity(0.3)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.background)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
        )
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OVERVIEW")
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                profileStat(value: "\(totalLogged)", label: "Days\nLogged", icon: "checkmark.square.fill", color: "39D353")
                profileStat(value: "\(longestStreak)", label: "Best\nStreak", icon: "flame.fill", color: "F78166")
                profileStat(value: "\(Int(overallRate * 100))%", label: "Overall\nRate", icon: "chart.bar.fill", color: "58A6FF")
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                profileStat(value: "\(activeCount)", label: "Active\nHabits", icon: "circle.grid.3x3.fill", color: "8957E5")
                profileStat(value: "\(quitCount)", label: "Quit\nHabits", icon: "minus.circle.fill", color: "FF7B72")
                profileStat(value: "\(completedCount)", label: "Periods\nDone", icon: "checkmark.seal.fill", color: "D2A8FF")
            }
        }
    }

    private func profileStat(value: String, label: String, icon: String, color: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
    }

    // MARK: - Habit Breakdown

    private var habitBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HABIT BREAKDOWN")
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)

            ForEach(allHabits) { habit in
                HStack(spacing: 12) {
                    Text(habit.emoji).font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(habit.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            if habit.isQuitHabit {
                                Text("\(habit.daysSinceRelapse)d")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "FF7B72"))
                            }
                            Spacer()
                            Text("\(Int(min(habit.completionRate, 1.0) * 100))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        let rate = min(habit.completionRate, 1.0)
                        ProgressView(value: rate)
                            .tint(Color(hex: habit.accentHex))
                            .scaleEffect(y: 1.2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)

            VStack(spacing: 0) {
                // Global Leaderboard Banner
                NavigationLink(destination: LeaderboardView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "FFA657"))
                            .frame(width: 28, height: 28)
                            .background(Color(hex: "FFA657").opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Global Leaderboard")
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Rank among HabitKit users")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if proManager.isLocked(.globalLeaderboard) {
                            ProBadge()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider().background(Theme.border)

                Button {
                    if proManager.requirePro(.dataExport, action: exportAsJSON) {
                    } else {
                        paywallFeature = .dataExport
                        showingPaywall = true
                    }
                } label: {
                    HStack {
                        settingsRowContent("Export Data (JSON)", icon: "square.and.arrow.up", color: "39D353")
                        if proManager.isLocked(.dataExport) { ProBadge(); Spacer().frame(width: 14) }
                    }
                }
                .buttonStyle(.plain)

                Divider().background(Theme.border)

                Button {
                    if proManager.requirePro(.dataExport, action: exportAsCSV) {
                    } else {
                        paywallFeature = .dataExport
                        showingPaywall = true
                    }
                } label: {
                    HStack {
                        settingsRowContent("Export Data (CSV)", icon: "tablecells", color: "58A6FF")
                        if proManager.isLocked(.dataExport) { ProBadge(); Spacer().frame(width: 14) }
                    }
                }
                .buttonStyle(.plain)

                Divider().background(Theme.border)

                // Remove profile photo
                if profileImageData != nil {
                    Button {
                        removeProfileImage()
                        HapticManager.light()
                    } label: {
                        settingsRowContent("Remove Profile Photo", icon: "person.crop.circle.badge.minus", color: "FF7B72")
                    }
                    .buttonStyle(.plain)

                    Divider().background(Theme.border)
                }

                settingsRow("Rate HabitKit", icon: "star.fill", color: "FFA657")
                Divider().background(Theme.border)
                settingsRow("Share with a Friend", icon: "square.and.arrow.up", color: "8957E5")
                Divider().background(Theme.border)

                Button {
                    hasCompletedOnboarding = false
                    HapticManager.light()
                } label: {
                    settingsRowContent("Replay Onboarding", icon: "play.fill", color: "D2A8FF")
                }
                .buttonStyle(.plain)

                Divider().background(Theme.border)

                #if canImport(RevenueCat)
                #if canImport(RevenueCatUI)
                if proManager.isPro {
                    Button {
                        showingCustomerCenter = true
                        HapticManager.light()
                    } label: {
                        settingsRowContent("Manage Subscription", icon: "person.text.rectangle.fill", color: "FFA657")
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingCustomerCenter) {
                        CustomerCenterView()
                    }
                    Divider().background(Theme.border)
                }
                #endif
                
                Button {
                    Task {
                        do {
                            let info = try await Purchases.shared.restorePurchases()
                            proManager.isPro = info.entitlements["habitkit Pro"]?.isActive == true
                            if proManager.isPro { HapticManager.success() }
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    settingsRowContent("Restore Purchases", icon: "arrow.triangle.2.circlepath", color: "58A6FF")
                }
                .buttonStyle(.plain)
                
                Divider().background(Theme.border)
                #endif

                // Logout
                Button {
                    authManager.logout()
                    HapticManager.warning()
                } label: {
                    settingsRowContent("Log Out", icon: "rectangle.portrait.and.arrow.right", color: "FF3B30")
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("HabitKit v1.0 • Made with 🤍")
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private func settingsRow(_ label: String, icon: String, color: String) -> some View {
        Button {} label: { settingsRowContent(label, icon: icon, color: color) }
            .buttonStyle(.plain)
    }

    private func settingsRowContent(_ label: String, icon: String, color: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: color))
                .frame(width: 28, height: 28)
                .background(Color(hex: color).opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            Text(label)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Photo Helpers

    private func saveProfileImage(_ data: Data) {
        try? data.write(to: profileImageURL)
        HapticManager.success()
    }

    private func loadProfileImage() {
        if let data = try? Data(contentsOf: profileImageURL) {
            profileImageData = data
        }
    }

    private func removeProfileImage() {
        try? FileManager.default.removeItem(at: profileImageURL)
        profileImageData = nil
    }

    // MARK: - Data Export

    private func exportAsJSON() {
        var exportArray: [[String: Any]] = []
        for habit in allHabits {
            var h: [String: Any] = [
                "name": habit.name,
                "emoji": habit.emoji,
                "type": habit.habitTypeRaw,
                "schedule": habit.scheduleDescription,
                "createdAt": ISO8601DateFormatter().string(from: habit.createdAt),
                "status": habit.statusRaw,
                "streak": habit.streak,
                "completionRate": habit.completionRate,
            ]
            if habit.isQuantifiable {
                h["goalValue"] = habit.goalValue
                h["goalUnit"] = habit.goalUnit
            }
            var logEntries: [[String: Any]] = []
            for log in habit.logs.sorted(by: { $0.date < $1.date }) {
                var entry: [String: Any] = [
                    "date": ISO8601DateFormatter().string(from: log.date),
                    "value": log.value,
                ]
                if log.isSkipped { entry["skipped"] = true }
                if !log.note.isEmpty { entry["note"] = log.note }
                if log.loggedAmount > 0 { entry["loggedAmount"] = log.loggedAmount }
                logEntries.append(entry)
            }
            h["logs"] = logEntries
            exportArray.append(h)
        }

        if let json = try? JSONSerialization.data(withJSONObject: exportArray, options: .prettyPrinted) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("habitkit_export.json")
            try? json.write(to: url)
            exportURL = url
            showingExportSheet = true
            HapticManager.success()
        }
    }

    private func exportAsCSV() {
        var csv = "Habit,Type,Date,Value,Logged Amount,Skipped,Note\n"
        for habit in allHabits {
            for log in habit.logs.sorted(by: { $0.date < $1.date }) {
                let dateStr = ISO8601DateFormatter().string(from: log.date)
                let note = log.note.replacingOccurrences(of: ",", with: ";")
                csv += "\(habit.name),\(habit.habitTypeRaw),\(dateStr),\(log.value),\(log.loggedAmount),\(log.isSkipped),\(note)\n"
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("habitkit_export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        exportURL = url
        showingExportSheet = true
        HapticManager.success()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    StarterPack.seedIfNeeded(context: container.mainContext)
    return ProfileView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
