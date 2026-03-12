//
//  HabitListView.swift
//  habitkit
//
//  Main screen: scrollable list of habit cards.
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .forward) private var habits: [Habit]

    @State private var showingAddSheet = false

    // Daily progress
    private var dailyProgress: Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter(\.isCompletedToday).count
        return Double(completed) / Double(habits.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.accent)

                        Text("HabitKit")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundStyle(Theme.textPrimary)
                    }
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

                ToolbarItem(placement: .topBarLeading) {
                    dailyProgressIndicator
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddHabitView()
            }
        }
    }

    // MARK: - Habit List

    private var habitList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(habits) { habit in
                    HabitRowView(habit: habit)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.textTertiary)

            VStack(spacing: 8) {
                Text("No habits yet")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)

                Text("Start building your streak.\nTap + to add your first habit.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddSheet = true
                HapticManager.light()
            } label: {
                Text("Add Habit")
                    .font(Theme.headlineFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent, in: Capsule())
            }
        }
    }

    // MARK: - Daily Progress

    private var dailyProgressIndicator: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 2.5)
                    .frame(width: 22, height: 22)

                Circle()
                    .trim(from: 0, to: dailyProgress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4), value: dailyProgress)
            }

            Text("\(Int(dailyProgress * 100))%")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Actions

    private func deleteHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(habit)
            HapticManager.warning()
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)

    // Seed some habits
    StarterPack.seedIfNeeded(context: container.mainContext)

    return HabitListView()
        .modelContainer(container)
}
