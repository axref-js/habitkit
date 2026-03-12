//
//  HeatmapView.swift
//  habitkit
//
//  GitHub-style contribution heatmap — supports skipped, vacation, and partial-completion.
//

import SwiftUI
import SwiftData

struct HeatmapView: View {
    let habit: Habit
    let weeks: Int

    @Environment(\.modelContext) private var modelContext

    private let rows = 7
    private let cellSize: CGFloat = Theme.cellSize
    private let spacing: CGFloat = Theme.gridSpacing

    // MARK: - Date Grid

    private var dateGrid: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let endOfCurrentWeek = calendar.date(byAdding: .day, value: 6 - daysFromMonday, to: today)!
        let totalDays = weeks * 7
        let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: endOfCurrentWeek)!
        return (0..<totalDays).map { calendar.date(byAdding: .day, value: $0, to: startDate)! }
    }

    private var monthLabels: [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var labels: [(String, Int)] = []
        var lastMonth = -1
        for (index, date) in dateGrid.enumerated() {
            let month = calendar.component(.month, from: date)
            let row = index % rows
            if month != lastMonth && row == 0 {
                labels.append((formatter.string(from: date), index / rows))
                lastMonth = month
            }
        }
        return labels
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    monthLabelRow
                    heatmapGrid
                }
                .padding(.trailing, 4)
                .id("heatmap-end")
            }
            .onAppear {
                proxy.scrollTo("heatmap-end", anchor: .trailing)
            }
        }
    }

    // MARK: - Subviews

    private var monthLabelRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(monthLabels.enumerated()), id: \.offset) { idx, label in
                Text(label.0)
                    .font(Theme.microFont)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: cellWidth(for: idx), alignment: .leading)
            }
        }
        .padding(.leading, 2)
    }

    private func cellWidth(for labelIndex: Int) -> CGFloat {
        let currentCol = monthLabels[labelIndex].1
        let nextCol = labelIndex + 1 < monthLabels.count ? monthLabels[labelIndex + 1].1 : weeks
        return CGFloat(nextCol - currentCol) * (cellSize + spacing)
    }

    private var heatmapGrid: some View {
        let grid = dateGrid
        let columns = weeks

        return HStack(spacing: spacing) {
            ForEach(0..<columns, id: \.self) { col in
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        let index = col * rows + row
                        if index < grid.count {
                            let date = grid[index]
                            let isFuture = date > Date.now
                            let logEntry = habit.logEntry(for: date)
                            let isSkipped = logEntry?.isSkipped ?? false
                            let isVacation = habit.isVacationDay(date)
                            let isScheduled = habit.isScheduled(for: date)
                            let value = habit.logValue(for: date)

                            HeatmapCell(
                                date: date,
                                value: value,
                                accentHex: habit.accentHex,
                                isFuture: isFuture,
                                isSkipped: isSkipped,
                                isVacation: isVacation,
                                isScheduled: isScheduled
                            ) {
                                guard !isFuture else { return }
                                toggleLog(for: date)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleLog(for date: Date) {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        if let existing = habit.logs.first(where: { calendar.isDate($0.date, inSameDayAs: target) }) {
            modelContext.delete(existing)
            HapticManager.light()
        } else {
            let log = HabitLog(date: target, value: 1.0, habit: habit)
            modelContext.insert(log)
            HapticManager.medium()
        }
    }
}

// MARK: - Heatmap Cell

private struct HeatmapCell: View {
    let date: Date
    let value: Double
    let accentHex: String
    let isFuture: Bool
    let isSkipped: Bool
    let isVacation: Bool
    let isScheduled: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(cellColor)
                .frame(width: Theme.cellSize, height: Theme.cellSize)

            // Skipped indicator: diagonal line
            if isSkipped {
                Image(systemName: "forward.fill")
                    .font(.system(size: 5))
                    .foregroundStyle(Color(hex: "FFA657").opacity(0.8))
            }

            // Vacation indicator: snowflake
            if isVacation && !isFuture {
                Image(systemName: "snowflake")
                    .font(.system(size: 5))
                    .foregroundStyle(Color(hex: "58A6FF").opacity(0.8))
            }
        }
        .scaleEffect(isPressed ? 1.4 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            guard !isFuture else { return }
            isPressed = true
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }
    }

    private var cellColor: Color {
        if isFuture { return Theme.background.opacity(0.3) }
        if isVacation { return Color(hex: "58A6FF").opacity(0.12) }
        if isSkipped { return Color(hex: "FFA657").opacity(0.12) }
        if !isScheduled { return Theme.background.opacity(0.15) }
        return Theme.heatmapColor(value: value, accentHex: accentHex)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    let habit = Habit(name: "Deep Work", emoji: "🧠", accentHex: "8957E5", benefit: "Focus blocks")
    container.mainContext.insert(habit)
    let calendar = Calendar.current
    for i in 0..<60 {
        if Bool.random() {
            let date = calendar.date(byAdding: .day, value: -i, to: .now)!
            let log = HabitLog(date: date, value: Double.random(in: 0.25...1.0), habit: habit)
            container.mainContext.insert(log)
        }
    }
    return HeatmapView(habit: habit, weeks: 16)
        .padding()
        .background(Theme.background)
        .modelContainer(container)
}
