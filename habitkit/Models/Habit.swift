//
//  Habit.swift
//  habitkit
//
//  Core habit model with SwiftData persistence.
//

import Foundation
import SwiftData

// MARK: - Enums

enum HabitStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case paused = "paused"
}

enum HabitDuration: Int, Codable, CaseIterable, Identifiable {
    case week1 = 7
    case week2 = 14
    case days21 = 21
    case month1 = 30
    case month2 = 60
    case month3 = 90
    case forever = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .week1: return "1 Week"
        case .week2: return "2 Weeks"
        case .days21: return "21 Days"
        case .month1: return "1 Month"
        case .month2: return "2 Months"
        case .month3: return "3 Months"
        case .forever: return "Forever"
        }
    }

    var subtitle: String {
        switch self {
        case .week1: return "Quick test run"
        case .week2: return "Build momentum"
        case .days21: return "Form the neural pathway"
        case .month1: return "Solidify the habit"
        case .month2: return "Deep integration"
        case .month3: return "Complete rewiring"
        case .forever: return "Lifelong commitment"
        }
    }
}

/// Schedule type: how often the habit repeats
enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"                 // Every day
    case specificDays = "specificDays"    // Mon/Wed/Fri etc
    case timesPerWeek = "timesPerWeek"   // X times per week (flexible)
    case interval = "interval"           // Every N days

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: return "Every Day"
        case .specificDays: return "Specific Days"
        case .timesPerWeek: return "Times per Week"
        case .interval: return "Every X Days"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .specificDays: return "calendar.badge.checkmark"
        case .timesPerWeek: return "number"
        case .interval: return "repeat"
        }
    }
}

/// Habit type: build (do something) vs quit (stop something)
enum HabitType: String, Codable {
    case build = "build"
    case quit = "quit"
}

// MARK: - Model

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "✅"
    var accentHex: String = "39D353"
    var benefit: String = ""
    var createdAt: Date = Date.now

    // Duration & status
    var durationDays: Int = 0
    var endDate: Date? = nil
    var statusRaw: String = "active"

    // === Phase 3A: Scheduling ===
    var scheduleTypeRaw: String = "daily"
    /// Bitmask for weekdays: bit 0 = Sun, bit 1 = Mon, ..., bit 6 = Sat
    var scheduleDaysMask: Int = 127           // 0b1111111 = every day
    var timesPerWeek: Int = 7
    var intervalDays: Int = 1

    // === Phase 3B: Quantifiable Goals ===
    var habitTypeRaw: String = "build"        // build or quit
    var goalValue: Double = 0.0               // 0 = simple yes/no
    var goalUnit: String = ""                 // "pages", "glasses", "minutes"

    // === Phase 4A: Quit Habits ===
    var lastRelapseDate: Date? = nil          // for quit habits

    // === Phase 4C: Vacation Mode ===
    var vacationStart: Date? = nil
    var vacationEnd: Date? = nil

    // === Phase 3D: Reminders ===
    var reminderEnabled: Bool = false
    var reminderHour: Int = 9
    var reminderMinute: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    // MARK: - Computed Wrappers

    var status: HabitStatus {
        get { HabitStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var scheduleType: ScheduleType {
        get { ScheduleType(rawValue: scheduleTypeRaw) ?? .daily }
        set { scheduleTypeRaw = newValue.rawValue }
    }

    var habitType: HabitType {
        get { HabitType(rawValue: habitTypeRaw) ?? .build }
        set { habitTypeRaw = newValue.rawValue }
    }

    /// Whether this habit tracks a quantity (vs simple yes/no)
    var isQuantifiable: Bool { goalValue > 0 }

    /// Whether this is a quit/negative habit
    var isQuitHabit: Bool { habitType == .quit }

    // MARK: - Init

    init(
        name: String,
        emoji: String = "✅",
        accentHex: String = "39D353",
        benefit: String = "",
        createdAt: Date = .now,
        duration: HabitDuration = .forever,
        scheduleType: ScheduleType = .daily,
        scheduleDaysMask: Int = 127,
        timesPerWeek: Int = 7,
        intervalDays: Int = 1,
        habitType: HabitType = .build,
        goalValue: Double = 0.0,
        goalUnit: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.accentHex = accentHex
        self.benefit = benefit
        self.createdAt = createdAt
        self.durationDays = duration.rawValue
        self.statusRaw = HabitStatus.active.rawValue
        self.scheduleTypeRaw = scheduleType.rawValue
        self.scheduleDaysMask = scheduleDaysMask
        self.timesPerWeek = timesPerWeek
        self.intervalDays = intervalDays
        self.habitTypeRaw = habitType.rawValue
        self.goalValue = goalValue
        self.goalUnit = goalUnit
        self.logs = []

        if duration != .forever {
            self.endDate = Calendar.current.date(byAdding: .day, value: duration.rawValue, to: createdAt)
        }
    }

    // MARK: - Scheduling

    /// Whether this habit is scheduled for a given date
    func isScheduled(for date: Date, using calendar: Calendar = Calendar.current) -> Bool {
        // Not scheduled before creation or after end
        if date < calendar.startOfDay(for: createdAt) { return false }
        if let endDate, date > endDate { return false }

        switch scheduleType {
        case .daily:
            return true

        case .specificDays:
            let weekday = calendar.component(.weekday, from: date) // 1=Sun, 7=Sat
            return (scheduleDaysMask >> (weekday - 1)) & 1 == 1

        case .timesPerWeek:
            // Flexible — always "available" but user picks which days
            return true

        case .interval:
            let daysSinceCreation = calendar.dateComponents([.day], from: createdAt, to: date).day ?? 0
            return daysSinceCreation % intervalDays == 0
        }
    }

    /// Whether this habit is scheduled for today
    var isScheduledToday: Bool { isScheduled(for: .now) }

    /// Number of scheduled days between two dates
    func scheduledDays(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let totalDays = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        guard totalDays > 0 else { return 0 }

        var count = 0
        for i in 0...totalDays {
            if let day = calendar.date(byAdding: .day, value: i, to: startDay),
               isScheduled(for: day, using: calendar) {
                count += 1
            }
        }
        return count
    }

    // MARK: - Vacation Mode

    var isOnVacation: Bool {
        guard let start = vacationStart, let end = vacationEnd else { return false }
        return Date.now >= start && Date.now <= end
    }

    func isVacationDay(_ date: Date) -> Bool {
        guard let start = vacationStart, let end = vacationEnd else { return false }
        return date >= start && date <= end
    }

    // MARK: - Status Helpers

    var isActive: Bool { status == .active }

    var isPeriodEnded: Bool {
        guard let endDate else { return false }
        return Date.now >= endDate && status == .active
    }

    var daysRemaining: Int? {
        guard let endDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0
        return max(days, 0)
    }

    var periodProgress: Double {
        guard durationDays > 0 else { return 0 }
        let elapsed = Calendar.current.dateComponents([.day], from: createdAt, to: .now).day ?? 0
        return min(Double(elapsed) / Double(durationDays), 1.0)
    }

    // MARK: - Quit Habit Helpers

    /// Days since last relapse (for quit habits)
    var daysSinceRelapse: Int {
        let calendar = Calendar.current
        let reference = lastRelapseDate ?? createdAt
        return calendar.dateComponents([.day], from: reference, to: .now).day ?? 0
    }

    // MARK: - Completion Helpers

    var isCompletedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return logs.contains { calendar.startOfDay(for: $0.date) == today && !$0.isSkipped }
    }

    var isSkippedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return logs.contains { calendar.startOfDay(for: $0.date) == today && $0.isSkipped }
    }

    func logValue(for date: Date) -> Double {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        return logs.first { calendar.startOfDay(for: $0.date) == target && !$0.isSkipped }?.value ?? 0.0
    }

    func logEntry(for date: Date) -> HabitLog? {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        return logs.first { calendar.startOfDay(for: $0.date) == target }
    }

    @discardableResult
    func toggleToday(context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        if let existing = logs.first(where: { calendar.startOfDay(for: $0.date) == today }) {
            context.delete(existing)
            return false
        } else {
            let val = isQuantifiable ? 0.0 : 1.0
            let log = HabitLog(date: today, value: val, loggedAmount: isQuantifiable ? 0 : goalValue, habit: self)
            context.insert(log)
            return true
        }
    }

    /// Log a specific quantity for today
    func logQuantity(_ amount: Double, context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let fraction = goalValue > 0 ? min(amount / goalValue, 1.0) : 1.0

        if let existing = logs.first(where: { calendar.startOfDay(for: $0.date) == today }) {
            existing.loggedAmount = amount
            existing.value = fraction
            existing.isSkipped = false
        } else {
            let log = HabitLog(date: today, value: fraction, loggedAmount: amount, habit: self)
            context.insert(log)
        }
    }

    /// Skip today — doesn't break streak
    func skipToday(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        if let existing = logs.first(where: { calendar.startOfDay(for: $0.date) == today }) {
            existing.isSkipped = true
            existing.value = 0
        } else {
            let log = HabitLog(date: today, value: 0, isSkipped: true, habit: self)
            context.insert(log)
        }
    }

    // MARK: - Streak (schedule-aware, skip-aware, vacation-aware)

    var streak: Int {
        let calendar = Calendar.current
        let logDates = Set(logs.filter { !$0.isSkipped }.map { calendar.startOfDay(for: $0.date) })
        let skippedDates = Set(logs.filter { $0.isSkipped }.map { calendar.startOfDay(for: $0.date) })

        var count = 0
        var checkDate = calendar.startOfDay(for: .now)

        for _ in 0..<365 {
            // Skip vacation days
            if isVacationDay(checkDate) {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }

            // Skip non-scheduled days
            if !isScheduled(for: checkDate, using: calendar) {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }

            // Skip explicitly skipped days
            if skippedDates.contains(checkDate) {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }

            if logDates.contains(checkDate) {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return count
    }

    // MARK: - Completion Rate (schedule-aware)

    var completionRate: Double {
        let scheduled = scheduledDays(from: createdAt, to: .now)
        guard scheduled > 0 else { return 0 }
        let completed = logs.filter { !$0.isSkipped }.count
        return Double(completed) / Double(scheduled)
    }

    var weeklyRate: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now)!
        let scheduled = scheduledDays(from: weekAgo, to: .now)
        guard scheduled > 0 else { return 0 }
        let recentLogs = logs.filter { $0.date >= weekAgo && !$0.isSkipped }
        return Double(recentLogs.count) / Double(scheduled)
    }

    // MARK: - Weekday Helpers

    /// Get selected weekday names from the bitmask
    var selectedDayNames: [String] {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return (0..<7).compactMap { bit in
            (scheduleDaysMask >> bit) & 1 == 1 ? names[bit] : nil
        }
    }

    /// Short schedule description for display
    var scheduleDescription: String {
        switch scheduleType {
        case .daily: return "Every day"
        case .specificDays: return selectedDayNames.joined(separator: ", ")
        case .timesPerWeek: return "\(timesPerWeek)× per week"
        case .interval: return "Every \(intervalDays) days"
        }
    }
}
