//
//  HabitReviewView.swift
//  habitkit
//
//  End-of-period habit review — shown when a habit's duration ends.
//

import SwiftUI
import SwiftData

struct HabitReviewView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Text(habit.emoji)
                            .font(.system(size: 56))

                        Text("Period Complete!")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)

                        Text("\(habit.name) — \(habit.durationDays) day challenge")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 20)

                    // Stats summary
                    statsGrid

                    // Heatmap review
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR JOURNEY")
                            .font(Theme.microFont)
                            .foregroundStyle(Theme.textTertiary)

                        HeatmapView(habit: habit, weeks: max(habit.durationDays / 7, 4))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(Theme.surface)
                    )

                    // Verdict
                    verdictCard

                    // Action buttons
                    VStack(spacing: 12) {
                        // Renew
                        Button {
                            renewHabit()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Renew for Another Period")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                        }

                        // Make permanent
                        Button {
                            makeForever()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "infinity")
                                Text("Keep Forever")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(Theme.accent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }

                        // Mark as done
                        Button {
                            markCompleted()
                        } label: {
                            Text("I'm done with this habit")
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textTertiary)
                                .underline()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            reviewStatCard(
                value: "\(habit.logs.count)",
                label: "Days Logged",
                icon: "checkmark.circle.fill",
                color: "39D353"
            )
            reviewStatCard(
                value: "\(Int(habit.completionRate * 100))%",
                label: "Completion Rate",
                icon: "chart.pie.fill",
                color: "58A6FF"
            )
            reviewStatCard(
                value: "\(habit.streak)",
                label: "Longest Streak",
                icon: "flame.fill",
                color: "F78166"
            )
            reviewStatCard(
                value: "\(habit.durationDays)",
                label: "Days Committed",
                icon: "calendar",
                color: "8957E5"
            )
        }
    }

    private func reviewStatCard(value: String, label: String, icon: String, color: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: color))

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surface)
        )
    }

    // MARK: - Verdict

    private var verdictCard: some View {
        let rate = habit.completionRate
        let verdict: (emoji: String, title: String, message: String) = {
            if rate >= 0.9 {
                return ("🏆", "Outstanding!", "You crushed it. This habit is part of who you are now.")
            } else if rate >= 0.7 {
                return ("💪", "Strong work!", "You showed up most days. That consistency compounds.")
            } else if rate >= 0.4 {
                return ("🌱", "Growing!", "You made real progress. Consider another round to solidify it.")
            } else {
                return ("🔄", "Worth another shot", "Habits take time. Try a shorter period to build momentum.")
            }
        }()

        return VStack(spacing: 10) {
            Text(verdict.emoji)
                .font(.system(size: 36))
            Text(verdict.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(verdict.message)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .strokeBorder(Color(hex: habit.accentHex).opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func renewHabit() {
        habit.createdAt = .now
        habit.endDate = Calendar.current.date(byAdding: .day, value: habit.durationDays, to: .now)
        habit.status = .active
        HapticManager.success()
        dismiss()
    }

    private func makeForever() {
        habit.durationDays = 0
        habit.endDate = nil
        habit.status = .active
        HapticManager.success()
        dismiss()
    }

    private func markCompleted() {
        habit.status = .completed
        HapticManager.medium()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)

    let habit = Habit(name: "Deep Work", emoji: "🧠", accentHex: "8957E5", benefit: "Focus blocks", duration: .days21)
    container.mainContext.insert(habit)

    let calendar = Calendar.current
    for i in 0..<21 {
        if Bool.random() || i < 15 {
            let date = calendar.date(byAdding: .day, value: -i, to: .now)!
            let log = HabitLog(date: date, value: 1.0, habit: habit)
            container.mainContext.insert(log)
        }
    }

    return HabitReviewView(habit: habit)
        .modelContainer(container)
}
