//
//  HomeView.swift
//  habitkit
//
//  Dashboard: quote, daily progress, today's habits (swipe gestures), analytics.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { $0.statusRaw == "active" },
           sort: \Habit.createdAt, order: .forward) private var activeHabits: [Habit]

    @AppStorage("userName") private var userName = ""
    @AppStorage("hasSeenHomeTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false
    @State private var showingQuantityInput: Habit?
    @State private var quantityInput: Double = 0
    @State private var showingJournalInput: Habit?
    @State private var journalText: String = ""

    @ObservedObject private var proManager = ProManager.shared
    @State private var showingPaywall = false

    // Today's scheduled habits
    private var todaysHabits: [Habit] {
        activeHabits.filter { $0.isScheduledToday && !$0.isOnVacation }
    }

    private var buildHabits: [Habit] { todaysHabits.filter { !$0.isQuitHabit } }
    private var quitHabits: [Habit] { todaysHabits.filter { $0.isQuitHabit } }

    private var dailyProgress: Double {
        guard !todaysHabits.isEmpty else { return 0 }
        let completed = todaysHabits.filter { $0.isCompletedToday || $0.isSkippedToday }.count
        return Double(completed) / Double(todaysHabits.count)
    }

    private var completedToday: Int {
        todaysHabits.filter(\.isCompletedToday).count
    }

    private var bestStreak: Int {
        activeHabits.map(\.streak).max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    greetingSection
                    quoteCard
                    progressSection
                    if !buildHabits.isEmpty { todayBuildSection }
                    if !quitHabits.isEmpty { todayQuitSection }
                    weeklyAnalyticsSection
                    if !expiringHabits.isEmpty { expiringSection }
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.accent)
                        Text("HabitKit")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $showingQuantityInput) { habit in
                quantitySheet(habit)
            }
            .sheet(item: $showingJournalInput) { habit in
                journalSheet(habit)
            }
            .sheet(isPresented: $showingPaywall) {
                ProPaywallSheet(highlightedFeature: .journaling)
            }
            .overlay {
                if showTutorial {
                    TutorialOverlay(pageName: "home", tips: Tutorials.home) {
                        showTutorial = false
                        hasSeenTutorial = true
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                if !hasSeenTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation { showTutorial = true }
                    }
                }
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = userName.isEmpty ? "" : ", \(userName)"
        switch hour {
        case 5..<12: return "Good morning\(name)"
        case 12..<17: return "Good afternoon\(name)"
        case 17..<21: return "Good evening\(name)"
        default: return "Night owl\(name)"
        }
    }

    // MARK: - Quote

    private var quoteCard: some View {
        let quote = MotivationQuotes.today
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.accent)
                Text("DAILY INSIGHT")
                    .font(Theme.microFont)
                    .foregroundStyle(Theme.accent)
            }
            Text(quote.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(quote.author)")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).strokeBorder(Theme.accent.opacity(0.15), lineWidth: 1))
        )
    }

    // MARK: - Progress

    private var progressSection: some View {
        HStack(spacing: 12) {
            progressRing
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    statCard(value: "\(completedToday)/\(todaysHabits.count)", label: "Today", icon: "checkmark.circle", color: "39D353")
                    statCard(value: "\(bestStreak)d", label: "Best Streak", icon: "flame.fill", color: "F78166")
                }
                HStack(spacing: 10) {
                    statCard(value: "\(Int(overallWeeklyRate * 100))%", label: "This Week", icon: "chart.bar.fill", color: "58A6FF")
                    statCard(value: "\(activeHabits.count)", label: "Active", icon: "circle.grid.3x3.fill", color: "8957E5")
                }
            }
        }
    }

    private var overallWeeklyRate: Double {
        guard !activeHabits.isEmpty else { return 0 }
        let rate = activeHabits.reduce(0.0) { $0 + $1.weeklyRate } / Double(activeHabits.count)
        return min(rate, 1.0)
    }

    private var progressRing: some View {
        ZStack {
            Circle().stroke(Theme.border, lineWidth: 8)
            Circle()
                .trim(from: 0, to: dailyProgress)
                .stroke(
                    LinearGradient(colors: [Theme.accent, Color(hex: "2EA043")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: dailyProgress)
            VStack(spacing: 2) {
                Text("\(Int(dailyProgress * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                Text("today")
                    .font(Theme.microFont)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(width: 120, height: 120)
    }

    private func statCard(value: String, label: String, icon: String, color: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: color))
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label)
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
    }

    // MARK: - Today's Build Habits (with swipe)

    private var todayBuildSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Today's Habits", icon: "calendar", count: "\(completedToday)/\(buildHabits.count)")

            Text("Swipe → complete · Swipe ← skip")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            ForEach(buildHabits) { habit in
                swipeableHabitRow(habit)
            }
        }
    }

    private func swipeableHabitRow(_ habit: Habit) -> some View {
        todayHabitRow(habit)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    if habit.isQuantifiable {
                        quantityInput = 0
                        showingQuantityInput = habit
                    } else {
                        let _ = habit.toggleToday(context: modelContext)
                        HapticManager.success()
                    }
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .tint(Color(hex: habit.accentHex))
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    habit.skipToday(context: modelContext)
                    HapticManager.light()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                }
                .tint(Color(hex: "FFA657"))
            }
    }

    private func todayHabitRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            Text(habit.emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Color(hex: habit.accentHex).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 8) {
                    // Schedule badge
                    if habit.scheduleType != .daily {
                        Text(habit.scheduleDescription)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    if habit.streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: habit.accentHex))
                            Text("\(habit.streak)d")
                                .font(Theme.microFont)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    // Quantity progress
                    if habit.isQuantifiable, let log = habit.logEntry(for: .now), !log.isSkipped {
                        Text("\(Int(log.loggedAmount))/\(Int(habit.goalValue)) \(habit.goalUnit)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: habit.accentHex))
                    }

                    if let remaining = habit.daysRemaining {
                        Text("\(remaining)d left")
                            .font(Theme.microFont)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            Spacer()

            // Status indicator
            if habit.isSkippedToday {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "FFA657"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "FFA657").opacity(0.1), in: Circle())
            } else {
                Button {
                    if habit.isQuantifiable {
                        quantityInput = habit.logEntry(for: .now)?.loggedAmount ?? 0
                        showingQuantityInput = habit
                    } else {
                        let _ = habit.toggleToday(context: modelContext)
                        HapticManager.success()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(habit.isCompletedToday ? Color(hex: habit.accentHex) : Theme.surfaceHover)
                            .frame(width: 36, height: 36)
                        if habit.isCompletedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        } else if habit.isQuantifiable {
                            Image(systemName: "number")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(habit.isCompletedToday ? Color(hex: habit.accentHex).opacity(0.06)
                      : habit.isSkippedToday ? Color(hex: "FFA657").opacity(0.04)
                      : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(habit.isCompletedToday ? Color(hex: habit.accentHex).opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeOut(duration: 0.2), value: habit.isCompletedToday)
        .animation(.easeOut(duration: 0.2), value: habit.isSkippedToday)
    }

    // MARK: - Today's Quit Habits

    private var todayQuitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Quit Tracker", icon: "minus.circle", count: "\(quitHabits.count)")

            ForEach(quitHabits) { habit in
                quitHabitRow(habit)
            }
        }
    }

    private func quitHabitRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            Text(habit.emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Color(hex: habit.accentHex).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                Text(habit.daysSinceRelapse == 0 ? "Started today" : "\(habit.daysSinceRelapse) days strong 💪")
                    .font(Theme.captionFont)
                    .foregroundStyle(habit.daysSinceRelapse >= 7 ? Color(hex: "39D353") : Theme.textSecondary)
            }

            Spacer()

            // Days counter
            VStack(spacing: 0) {
                Text("\(habit.daysSinceRelapse)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: habit.accentHex))
                Text("days")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }

            // Relapse button
            Button {
                habit.lastRelapseDate = .now
                HapticManager.warning()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "FF7B72"))
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "FF7B72").opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: habit.accentHex).opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Quantity Input Sheet

    private func quantitySheet(_ habit: Habit) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(habit.emoji)
                    .font(.system(size: 48))
                Text(habit.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                VStack(spacing: 8) {
                    Text("\(Int(quantityInput))")
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                    Text("of \(Int(habit.goalValue)) \(habit.goalUnit)")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Theme.border).frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: habit.accentHex))
                                .frame(width: geo.size.width * min(quantityInput / max(habit.goalValue, 1), 1), height: 6)
                                .animation(.spring, value: quantityInput)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 40)
                }

                // Stepper buttons
                HStack(spacing: 16) {
                    stepperButton("-5") { quantityInput = max(0, quantityInput - 5) }
                    stepperButton("-1") { quantityInput = max(0, quantityInput - 1) }
                    stepperButton("+1") { quantityInput += 1 }
                    stepperButton("+5") { quantityInput += 5 }
                }

                Spacer()

                Button {
                    habit.logQuantity(quantityInput, context: modelContext)
                    HapticManager.success()
                    showingQuantityInput = nil
                } label: {
                    Text(quantityInput >= habit.goalValue ? "Goal Reached! ✅" : "Log Progress")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: habit.accentHex), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { showingQuantityInput = nil } label: {
                        Image(systemName: "xmark").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private func stepperButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.light()
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 52, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Journal Sheet

    private func journalSheet(_ habit: Habit) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text(habit.emoji).font(.system(size: 24))
                    Text(habit.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                Text("How did it go today?")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)

                TextEditor(text: $journalText)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                    )

                Button {
                    if let log = habit.logEntry(for: .now) {
                        log.note = journalText
                    }
                    HapticManager.success()
                    showingJournalInput = nil
                } label: {
                    Text("Save Note")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }

                Spacer()
            }
            .padding(24)
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { showingJournalInput = nil } label: {
                        Image(systemName: "xmark").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    // MARK: - Weekly Analytics

    private var weeklyAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Weekly Progress", icon: "chart.bar.fill")
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: -(6 - dayOffset), to: .now)!
                        let rate = dayCompletionRate(for: date)
                        VStack(spacing: 4) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4).fill(Theme.border.opacity(0.5)).frame(height: 60)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [Theme.accent.opacity(0.6), Theme.accent], startPoint: .bottom, endPoint: .top))
                                    .frame(height: max(CGFloat(rate) * 60, rate > 0 ? 4 : 0))
                            }
                            .frame(height: 60)
                            Text(dayLabel(for: date))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(Calendar.current.isDateInToday(date) ? Theme.accent : Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                HStack {
                    Text("Avg: \(Int(overallWeeklyRate * 100))%")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(weeklyTrend)
                        .font(Theme.captionFont)
                        .foregroundStyle(weeklyTrendColor)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: Theme.cornerRadius).fill(Theme.surface))
        }
    }

    private func dayCompletionRate(for date: Date) -> Double {
        let scheduled = activeHabits.filter { $0.isScheduled(for: date) && !$0.isQuitHabit }
        guard !scheduled.isEmpty else { return 0 }
        let completed = scheduled.filter { $0.logValue(for: date) > 0 }.count
        return Double(completed) / Double(scheduled.count)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(2)).uppercased()
    }

    private var weeklyTrend: String {
        let r = overallWeeklyRate
        if r >= 0.8 { return "🔥 On fire!" }
        if r >= 0.5 { return "📈 Good momentum" }
        if r > 0 { return "💪 Keep pushing" }
        return "🌱 Start today"
    }

    private var weeklyTrendColor: Color {
        let r = overallWeeklyRate
        if r >= 0.8 { return Color(hex: "F78166") }
        if r >= 0.5 { return Theme.accent }
        return Theme.textSecondary
    }

    // MARK: - Expiring

    private var expiringHabits: [Habit] {
        activeHabits.filter { ($0.daysRemaining ?? 999) <= 3 && ($0.daysRemaining ?? 0) > 0 }
    }

    private var expiringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Ending Soon", icon: "clock.badge.exclamationmark")
            ForEach(expiringHabits) { habit in
                HStack(spacing: 10) {
                    Text(habit.emoji).font(.system(size: 18))
                    Text(habit.name).font(Theme.bodyFont).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(habit.daysRemaining ?? 0)d left")
                        .font(Theme.captionFont)
                        .foregroundStyle(Color(hex: "FFA657"))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "FFA657").opacity(0.12)))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, count: String? = nil) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            if let count {
                Text(count)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    StarterPack.seedIfNeeded(context: container.mainContext)
    return HomeView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
