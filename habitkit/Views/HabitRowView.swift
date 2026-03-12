//
//  HabitRowView.swift
//  habitkit
//
//  Habit card with heatmap, streak, schedule info, goal progress, and quit counter.
//

import SwiftUI
import SwiftData

struct HabitRowView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext

    @State private var showCompletionPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row
            HStack(alignment: .center, spacing: 10) {
                // Emoji badge
                Text(habit.emoji)
                    .font(.system(size: 24))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: habit.accentHex).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Name & info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.textPrimary)

                        if habit.isQuitHabit {
                            Text("QUIT")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(Color(hex: "FF7B72"))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "FF7B72").opacity(0.12)))
                        }

                        if habit.isOnVacation {
                            Image(systemName: "snowflake")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "58A6FF"))
                        }
                    }

                    HStack(spacing: 8) {
                        if habit.isQuitHabit {
                            Text("\(habit.daysSinceRelapse) days clean")
                                .font(Theme.captionFont)
                                .foregroundStyle(habit.daysSinceRelapse >= 7 ? Color(hex: "39D353") : Theme.textSecondary)
                        } else {
                            Text(habit.benefit)
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Schedule badge
                if habit.scheduleType != .daily {
                    Text(habit.scheduleDescription)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.surfaceHover))
                }

                // Streak badge
                if habit.streak > 0 {
                    streakBadge
                }

                // Today toggle (build habits only)
                if !habit.isQuitHabit {
                    todayButton
                }
            }

            // Goal progress bar (quantifiable build habits)
            if habit.isQuantifiable && !habit.isQuitHabit {
                goalProgressBar
            }

            // Heatmap (last 16 weeks)
            HeatmapView(habit: habit, weeks: 16)
        }
        .padding(Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(
                    showCompletionPulse ? Color(hex: habit.accentHex).opacity(0.6) : Color.clear,
                    lineWidth: 1.5
                )
                .animation(.easeOut(duration: 0.5), value: showCompletionPulse)
        )
    }

    // MARK: - Subviews

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: habit.accentHex))
            Text("\(habit.streak)")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color(hex: habit.accentHex).opacity(0.12)))
    }

    private var todayButton: some View {
        Button {
            let completed = habit.toggleToday(context: modelContext)
            if completed {
                HapticManager.success()
                withAnimation(.spring(response: 0.3)) { showCompletionPulse = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation { showCompletionPulse = false }
                }
            } else {
                HapticManager.light()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(habit.isCompletedToday ? Color(hex: habit.accentHex) : Theme.surfaceHover)
                    .frame(width: 32, height: 32)
                Image(systemName: habit.isCompletedToday ? "checkmark" : "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(habit.isCompletedToday ? .white : Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .contentTransition(.symbolEffect(.replace))
    }

    private var goalProgressBar: some View {
        let todayLog = habit.logEntry(for: .now)
        let logged = todayLog?.loggedAmount ?? 0
        let fraction = habit.goalValue > 0 ? min(logged / habit.goalValue, 1.0) : 0

        return VStack(spacing: 4) {
            HStack {
                Text("\(Int(logged))/\(Int(habit.goalValue)) \(habit.goalUnit)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: habit.accentHex))
                Spacer()
                Text("\(Int(fraction * 100))%")
                    .font(Theme.microFont)
                    .foregroundStyle(Theme.textTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Theme.border).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: habit.accentHex))
                        .frame(width: geo.size.width * fraction, height: 4)
                        .animation(.spring, value: fraction)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    let habit = Habit(name: "Deep Work", emoji: "🧠", accentHex: "8957E5",
                      benefit: "90-min focus blocks boost BDNF.", goalValue: 90, goalUnit: "minutes")
    container.mainContext.insert(habit)
    let calendar = Calendar.current
    for i in 0..<50 {
        if Bool.random() {
            let date = calendar.date(byAdding: .day, value: -i, to: .now)!
            let log = HabitLog(date: date, value: 1.0, habit: habit)
            container.mainContext.insert(log)
        }
    }
    return HabitRowView(habit: habit)
        .padding()
        .background(Theme.background)
        .modelContainer(container)
}
