//
//  HabitLog.swift
//  habitkit
//
//  A single day's completion record for a habit.
//

import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID = UUID()
    var date: Date = Date.now
    /// 0.0 – 1.0 representing completion fraction
    var value: Double = 1.0
    /// Actual quantity logged (e.g. 15 pages out of 20)
    var loggedAmount: Double = 0.0
    /// Whether this day was skipped (doesn't break streak)
    var isSkipped: Bool = false
    /// Optional journal note
    var note: String = ""

    var habit: Habit?

    init(date: Date, value: Double = 1.0, loggedAmount: Double = 0.0, isSkipped: Bool = false, note: String = "", habit: Habit? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.value = min(max(value, 0), 1)
        self.loggedAmount = loggedAmount
        self.isSkipped = isSkipped
        self.note = note
        self.habit = habit
    }
}
