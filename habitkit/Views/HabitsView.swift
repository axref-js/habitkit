//
//  HabitsView.swift
//  habitkit
//
//  Full habit management: active/completed filters, vacation mode, review banners.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .forward) private var allHabits: [Habit]

    @State private var showingAddSheet = false
    @State private var habitToReview: Habit?
    @State private var selectedFilter: HabitFilter = .active
    @State private var vacationHabit: Habit?
    @State private var vacationDays: Int = 7
    @AppStorage("hasSeenHabitsTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false

    @ObservedObject private var proManager = ProManager.shared
    @State private var showingPaywall = false

    enum HabitFilter: String, CaseIterable {
        case active = "Active"
        case quit = "Quit"
        case completed = "Completed"
        case all = "All"
    }

    private var filteredHabits: [Habit] {
        switch selectedFilter {
        case .active: return allHabits.filter { $0.isActive && !$0.isQuitHabit }
        case .quit: return allHabits.filter { $0.isActive && $0.isQuitHabit }
        case .completed: return allHabits.filter { $0.status == .completed }
        case .all: return allHabits
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    if filteredHabits.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        habitList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Habits")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                        HapticManager.light()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(Theme.surface, in: Circle())
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddHabitView()
            }
            .sheet(item: $habitToReview) { habit in
                HabitReviewView(habit: habit)
            }
            .sheet(isPresented: $showingPaywall) {
                ProPaywallSheet(highlightedFeature: .vacationMode)
            }
            .sheet(item: $vacationHabit) { habit in
                vacationSheet(habit)
            }
            .overlay {
                if showTutorial {
                    TutorialOverlay(pageName: "habits", tips: Tutorials.habits) {
                        showTutorial = false
                        hasSeenTutorial = true
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                checkForExpiredHabits()
                if !hasSeenTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation { showTutorial = true }
                    }
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterCounts: [HabitFilter: Int] {
        var counts: [HabitFilter: Int] = [.active: 0, .quit: 0, .completed: 0, .all: allHabits.count]
        for habit in allHabits {
            if habit.status == .completed {
                counts[.completed, default: 0] += 1
            } else if habit.isActive {
                if habit.isQuitHabit {
                    counts[.quit, default: 0] += 1
                } else {
                    counts[.active, default: 0] += 1
                }
            }
        }
        return counts
    }

    private var filterBar: some View {
        let counts = filterCounts
        return HStack(spacing: 8) {
            ForEach(HabitFilter.allCases, id: \.self) { filter in
                let isSelected = selectedFilter == filter
                let count = counts[filter] ?? 0
                Button {
                    selectedFilter = filter
                    HapticManager.light()
                } label: {
                    HStack(spacing: 5) {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(isSelected ? Theme.accent.opacity(0.3) : Theme.border))
                        }
                    }
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isSelected ? Theme.accent.opacity(0.1) : Theme.surface)
                            .overlay(Capsule().strokeBorder(isSelected ? Theme.accent.opacity(0.3) : Theme.border, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }



    // MARK: - Habit List

    private var habitList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(expiredHabits) { habit in
                    reviewBanner(habit)
                }
                ForEach(filteredHabits) { habit in
                    HabitRowView(habit: habit)
                        .contextMenu {
                            // Vacation mode
                            if habit.isActive && !habit.isQuitHabit {
                                if habit.isOnVacation {
                                    Button {
                                        habit.vacationStart = nil
                                        habit.vacationEnd = nil
                                        HapticManager.medium()
                                    } label: {
                                        Label("End Vacation", systemImage: "sun.max.fill")
                                    }
                                } else {
                                    Button {
                                        if proManager.requirePro(.vacationMode, action: {
                                            vacationHabit = habit
                                        }) == false {
                                            showingPaywall = true
                                        }
                                    } label: {
                                        Label(proManager.isLocked(.vacationMode) ? "Freeze Streak (Pro)" : "Freeze Streak", systemImage: proManager.isLocked(.vacationMode) ? "lock.fill" : "snowflake")
                                    }
                                }
                            }

                            // Pause / Resume
                            if habit.isActive {
                                Button {
                                    habit.status = .paused
                                    HapticManager.medium()
                                } label: {
                                    Label("Pause", systemImage: "pause.circle")
                                }
                            } else if habit.status == .paused {
                                Button {
                                    habit.status = .active
                                    HapticManager.medium()
                                } label: {
                                    Label("Resume", systemImage: "play.circle")
                                }
                            }

                            if habit.status == .completed {
                                Button {
                                    habit.status = .active
                                    habit.createdAt = .now
                                    if habit.durationDays > 0 {
                                        habit.endDate = Calendar.current.date(byAdding: .day, value: habit.durationDays, to: .now)
                                    }
                                    HapticManager.medium()
                                } label: {
                                    Label("Reactivate", systemImage: "arrow.clockwise")
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private var expiredHabits: [Habit] {
        allHabits.filter(\.isPeriodEnded)
    }

    private func reviewBanner(_ habit: Habit) -> some View {
        Button {
            habitToReview = habit
            HapticManager.medium()
        } label: {
            HStack(spacing: 12) {
                Text(habit.emoji).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(habit.name) period ended")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tap to review your progress")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "FFA657"))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "FFA657").opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "FFA657").opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Vacation Sheet

    private func vacationSheet(_ habit: Habit) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "snowflake")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "58A6FF"))

                Text("Freeze Streak")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Text("Your streak won't break during this time. Max 7 days.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                // Day picker
                HStack(spacing: 0) {
                    Button {
                        vacationDays = max(1, vacationDays - 1)
                        HapticManager.light()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    Text("\(vacationDays)")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "58A6FF"))
                        .frame(width: 60)
                    Button {
                        vacationDays = min(7, vacationDays + 1)
                        HapticManager.light()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))

                Text("days")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                Button {
                    habit.vacationStart = .now
                    habit.vacationEnd = Calendar.current.date(byAdding: .day, value: vacationDays, to: .now)
                    HapticManager.success()
                    vacationHabit = nil
                } label: {
                    Text("Freeze Now ❄️")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "58A6FF"), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { vacationHabit = nil } label: {
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter == .completed ? "checkmark.seal" : selectedFilter == .quit ? "minus.circle" : "square.grid.3x3.fill")
                .font(.system(size: 42))
                .foregroundStyle(Theme.textTertiary)
            Text(emptyTitle)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)
            Text(emptySubtitle)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .completed: return "No completed habits yet"
        case .quit: return "No quit habits yet"
        default: return "No habits yet"
        }
    }

    private var emptySubtitle: String {
        switch selectedFilter {
        case .completed: return "Complete a habit period to see it here."
        case .quit: return "Tap + to add a quit habit."
        default: return "Tap + to create your first habit."
        }
    }

    // MARK: - Actions

    private func deleteHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(habit)
            HapticManager.warning()
        }
    }

    private func checkForExpiredHabits() {
        for habit in allHabits where habit.isPeriodEnded {
            if habitToReview == nil {
                habitToReview = habit
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    StarterPack.seedIfNeeded(context: container.mainContext)
    return HabitsView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
