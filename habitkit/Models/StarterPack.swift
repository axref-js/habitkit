//
//  StarterPack.swift
//  habitkit
//
//  Pre-set library of common habits with science-backed benefits.
//

import Foundation
import SwiftData

struct StarterHabit: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let accentHex: String
    let benefit: String
    let suggestedDuration: HabitDuration
    let scheduleType: ScheduleType
    let habitType: HabitType
    let goalValue: Double
    let goalUnit: String

    init(
        name: String, emoji: String, accentHex: String, benefit: String,
        suggestedDuration: HabitDuration = .days21,
        scheduleType: ScheduleType = .daily,
        habitType: HabitType = .build,
        goalValue: Double = 0, goalUnit: String = ""
    ) {
        self.name = name
        self.emoji = emoji
        self.accentHex = accentHex
        self.benefit = benefit
        self.suggestedDuration = suggestedDuration
        self.scheduleType = scheduleType
        self.habitType = habitType
        self.goalValue = goalValue
        self.goalUnit = goalUnit
    }
}

enum StarterPack {

    static let habits: [StarterHabit] = [
        // Build habits
        StarterHabit(
            name: "Deep Work", emoji: "🧠", accentHex: "8957E5",
            benefit: "90-min focus blocks boost BDNF, strengthening neural pathways.",
            suggestedDuration: .days21, goalValue: 90, goalUnit: "minutes"
        ),
        StarterHabit(
            name: "Hydration", emoji: "💧", accentHex: "58A6FF",
            benefit: "Even 2% dehydration impairs cognition. 8 glasses resets the baseline.",
            suggestedDuration: .month1, goalValue: 8, goalUnit: "glasses"
        ),
        StarterHabit(
            name: "Mindfulness", emoji: "🧘", accentHex: "D2A8FF",
            benefit: "10 min of meditation thickens the prefrontal cortex in 8 weeks.",
            suggestedDuration: .month2, goalValue: 10, goalUnit: "minutes"
        ),
        StarterHabit(
            name: "Movement", emoji: "🏃", accentHex: "F78166",
            benefit: "30 min of exercise elevates mood-regulating serotonin for 24 hours.",
            suggestedDuration: .month1, goalValue: 30, goalUnit: "minutes"
        ),
        StarterHabit(
            name: "Reading", emoji: "📖", accentHex: "39D353",
            benefit: "6 min of reading reduces cortisol-driven stress by 68%.",
            suggestedDuration: .days21, goalValue: 20, goalUnit: "pages"
        ),
        // Quit habits
        StarterHabit(
            name: "No Social Media", emoji: "📵", accentHex: "FF7B72",
            benefit: "Reclaim 2+ hours daily. Your prefrontal cortex will thank you.",
            suggestedDuration: .month1, habitType: .quit
        ),
        StarterHabit(
            name: "No Sugar", emoji: "🚫", accentHex: "FFA657",
            benefit: "After 10 days without sugar, taste receptors reset and cravings fade.",
            suggestedDuration: .days21, habitType: .quit
        ),
    ]

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Habit>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for starter in habits {
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
            context.insert(habit)
        }
    }
}
