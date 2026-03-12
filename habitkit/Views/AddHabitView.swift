//
//  AddHabitView.swift
//  habitkit
//
//  Bottom sheet for creating a new habit with full configuration.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allHabits: [Habit]

    @ObservedObject private var proManager = ProManager.shared
    @State private var showingPaywall = false
    @State private var paywallFeature: ProFeature?

    // Basic
    @State private var name = ""
    @State private var emoji = "✅"
    @State private var selectedAccent = "39D353"
    @State private var benefit = ""
    @State private var selectedDuration: HabitDuration = .days21

    // Type
    @State private var habitType: HabitType = .build

    // Schedule
    @State private var scheduleType: ScheduleType = .daily
    @State private var scheduleDaysMask: Int = 127
    @State private var timesPerWeek: Int = 3
    @State private var intervalDays: Int = 2

    // Goal
    @State private var isQuantifiable = false
    @State private var goalValue: Double = 1
    @State private var goalUnit = ""

    // Reminders
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? .now

    private let accentOptions = [
        "39D353", "8957E5", "58A6FF", "F78166",
        "D2A8FF", "FFA657", "FF7B72", "79C0FF",
    ]

    private let emojiOptions = [
        "✅", "🧠", "💧", "🧘", "🏃", "📖",
        "💪", "🎯", "🌅", "💤", "🥗", "✍️",
        "📵", "🚫", "🍷", "🚬", "📱", "🧊",
    ]

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    starterPackSection
                    divider
                    customHabitSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Theme.background)
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createHabit() }
                        .fontWeight(.semibold)
                        .foregroundStyle(name.isEmpty ? Theme.textTertiary : Theme.accent)
                        .disabled(name.isEmpty)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showingPaywall) {
            ProPaywallSheet(highlightedFeature: paywallFeature)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Starter Pack

    private var starterPackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Starter Pack", systemImage: "sparkles")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)

            Text("Quick-add a science-backed habit")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)

            ForEach(StarterPack.habits) { starter in
                starterRow(starter)
            }
        }
    }

    private func starterRow(_ starter: StarterHabit) -> some View {
        Button {
            addStarterHabit(starter)
        } label: {
            HStack(spacing: 12) {
                Text(starter.emoji)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: starter.accentHex).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(starter.name)
                            .font(Theme.bodyFont)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.textPrimary)

                        if starter.habitType == .quit {
                            Text("QUIT")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(Color(hex: "FF7B72"))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "FF7B72").opacity(0.12)))
                        }

                        if starter.goalValue > 0 {
                            Text("\(Int(starter.goalValue)) \(starter.goalUnit)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: starter.accentHex))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: starter.accentHex).opacity(0.12)))
                        }
                    }

                    Text(starter.benefit)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: starter.accentHex))
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Habit

    private var customHabitSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Custom Habit", systemImage: "plus.diamond")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)

            // Habit type toggle
            habitTypeSection

            // Name
            fieldSection("NAME") {
                TextField(habitType == .quit ? "e.g. No Soda" : "e.g. Cold Shower", text: $name)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .background(fieldBackground)
            }

            // Schedule
            scheduleSection

            // Duration
            durationSection

            // Goal (build habits only)
            if habitType == .build {
                goalSection
            }

            // Emoji picker
            fieldSection("ICON") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                    ForEach(emojiOptions, id: \.self) { option in
                        Text(option)
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(emoji == option ? Theme.surfaceHover : Theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(emoji == option ? Color(hex: selectedAccent) : Color.clear, lineWidth: 2)
                                    )
                            )
                            .onTapGesture {
                                emoji = option
                                HapticManager.light()
                            }
                    }
                }
            }

            // Color picker
            fieldSection("COLOR") {
                HStack(spacing: 10) {
                    ForEach(accentOptions, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().strokeBorder(.white.opacity(selectedAccent == hex ? 0.8 : 0), lineWidth: 2))
                            .scaleEffect(selectedAccent == hex ? 1.15 : 1.0)
                            .animation(.spring(response: 0.25), value: selectedAccent)
                            .onTapGesture {
                                selectedAccent = hex
                                HapticManager.light()
                            }
                    }
                }
            }

            // Benefit
            fieldSection("BENEFIT (OPTIONAL)") {
                TextField("Why this habit matters...", text: $benefit)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .background(fieldBackground)
            }

            // Reminder
            reminderSection
        }
    }

    // MARK: - Habit Type

    private var habitTypeSection: some View {
        fieldSection("HABIT TYPE") {
            HStack(spacing: 8) {
                typeButton("Build", subtitle: "Start doing", type: .build, color: "39D353", icon: "plus.circle.fill")
                typeButton("Quit", subtitle: "Stop doing", type: .quit, color: "FF7B72", icon: "minus.circle.fill")
            }
        }
    }

    private func typeButton(_ title: String, subtitle: String, type: HabitType, color: String, icon: String) -> some View {
        let isSelected = habitType == type
        return Button {
            habitType = type
            HapticManager.light()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: color))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: color).opacity(0.08) : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Color(hex: color).opacity(0.4) : Theme.border, lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        fieldSection("SCHEDULE") {
            VStack(spacing: 10) {
                // Schedule type picker
                HStack(spacing: 6) {
                    ForEach(ScheduleType.allCases) { type in
                        let isSelected = scheduleType == type
                        Button {
                            if type != .daily && !proManager.isPro {
                                paywallFeature = .advancedScheduling
                                showingPaywall = true
                            } else {
                                scheduleType = type
                                HapticManager.light()
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 14))
                                HStack(spacing: 2) {
                                    Text(type == .timesPerWeek ? "X/Week" : type == .interval ? "Interval" : type == .specificDays ? "Days" : "Daily")
                                        .font(.system(size: 9, weight: .medium))
                                    if type != .daily && proManager.isLocked(.advancedScheduling) {
                                        Image(systemName: "lock.fill").font(.system(size: 8))
                                    }
                                }
                            }
                            .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Theme.accent.opacity(0.1) : Theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(isSelected ? Theme.accent.opacity(0.3) : Theme.border, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Schedule-specific config
                switch scheduleType {
                case .specificDays:
                    weekdayPicker
                case .timesPerWeek:
                    timesPerWeekPicker
                case .interval:
                    intervalPicker
                case .daily:
                    EmptyView()
                }
            }
        }
    }

    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { idx in
                let isOn = (scheduleDaysMask >> idx) & 1 == 1
                Button {
                    scheduleDaysMask ^= (1 << idx)
                    HapticManager.light()
                } label: {
                    Text(weekdays[idx])
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isOn ? .white : Theme.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isOn ? Theme.accent : Theme.surface)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var timesPerWeekPicker: some View {
        HStack(spacing: 12) {
            Text("Times per week:")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            HStack(spacing: 0) {
                Button {
                    timesPerWeek = max(1, timesPerWeek - 1)
                    HapticManager.light()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                Text("\(timesPerWeek)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)
                Button {
                    timesPerWeek = min(7, timesPerWeek + 1)
                    HapticManager.light()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
        }
    }

    private var intervalPicker: some View {
        HStack(spacing: 12) {
            Text("Every")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            HStack(spacing: 0) {
                Button {
                    intervalDays = max(2, intervalDays - 1)
                    HapticManager.light()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                Text("\(intervalDays)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)
                Button {
                    intervalDays = min(30, intervalDays + 1)
                    HapticManager.light()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))

            Text("days")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        fieldSection("COMMITMENT PERIOD") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(HabitDuration.allCases) { duration in
                    durationCard(duration)
                }
            }
        }
    }

    private func durationCard(_ duration: HabitDuration) -> some View {
        let isSelected = selectedDuration == duration
        return Button {
            selectedDuration = duration
            HapticManager.light()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(duration.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textPrimary)
                Text(duration.subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Theme.accent.opacity(0.08) : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Theme.accent.opacity(0.4) : Theme.border, lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Goal

    private var goalSection: some View {
        fieldSection("DAILY GOAL") {
            VStack(spacing: 10) {
                // Toggle
                HStack {
                    Image(systemName: isQuantifiable ? "number.circle.fill" : "checkmark.circle")
                        .foregroundStyle(isQuantifiable ? Theme.accent : Theme.textTertiary)
                    Text(isQuantifiable ? "Track a quantity" : "Simple yes/no")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Toggle("", isOn: $isQuantifiable)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))

                if isQuantifiable {
                    HStack(spacing: 10) {
                        // Goal amount
                        HStack(spacing: 0) {
                            Button {
                                goalValue = max(1, goalValue - 1)
                                HapticManager.light()
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 32, height: 32)
                            }
                            Text("\(Int(goalValue))")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 44)
                            Button {
                                goalValue += 1
                                HapticManager.light()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))

                        // Unit
                        TextField("unit (pages, min...)", text: $goalUnit)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(fieldBackground)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeOut(duration: 0.25), value: isQuantifiable)
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        fieldSection("DAILY REMINDER") {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: reminderEnabled ? "bell.fill" : "bell.slash")
                        .foregroundStyle(reminderEnabled ? Theme.accent : Theme.textTertiary)
                    Text(reminderEnabled ? "Reminder on" : "No reminder")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))

                if reminderEnabled {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accent)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeOut(duration: 0.25), value: reminderEnabled)
        }
    }

    // MARK: - Helpers

    private func fieldSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.microFont)
                .foregroundStyle(Theme.textTertiary)
            content()
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1))
    }

    private var divider: some View {
        Rectangle().fill(Theme.border).frame(height: 1)
    }

    // MARK: - Actions

    private func createHabit() {
        if allHabits.count >= ProManager.freeHabitLimit && !proManager.isPro {
            paywallFeature = .unlimitedHabits
            showingPaywall = true
            return
        }
        guard !name.isEmpty else { return }
        let hour = Calendar.current.component(.hour, from: reminderTime)
        let minute = Calendar.current.component(.minute, from: reminderTime)

        let habit = Habit(
            name: name,
            emoji: emoji,
            accentHex: selectedAccent,
            benefit: benefit,
            duration: selectedDuration,
            scheduleType: scheduleType,
            scheduleDaysMask: scheduleType == .specificDays ? scheduleDaysMask : 127,
            timesPerWeek: timesPerWeek,
            intervalDays: intervalDays,
            habitType: habitType,
            goalValue: isQuantifiable ? goalValue : 0,
            goalUnit: isQuantifiable ? goalUnit : ""
        )
        habit.reminderEnabled = reminderEnabled
        habit.reminderHour = hour
        habit.reminderMinute = minute
        modelContext.insert(habit)
        HapticManager.success()
        dismiss()
    }

    private func addStarterHabit(_ starter: StarterHabit) {
        if allHabits.count >= ProManager.freeHabitLimit && !proManager.isPro {
            paywallFeature = .unlimitedHabits
            showingPaywall = true
            return
        }
        let habit = Habit(
            name: starter.name,
            emoji: starter.emoji,
            accentHex: starter.accentHex,
            benefit: starter.benefit,
            duration: starter.suggestedDuration,
            scheduleType: starter.scheduleType,
            habitType: starter.habitType,
            goalValue: starter.goalValue,
            goalUnit: starter.goalUnit
        )
        modelContext.insert(habit)
        HapticManager.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
