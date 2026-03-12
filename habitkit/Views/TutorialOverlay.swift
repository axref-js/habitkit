//
//  TutorialOverlay.swift
//  habitkit
//
//  Reusable per-page tutorial tips — shown only on first visit.
//

import SwiftUI

/// A single tutorial tip with icon, title, and description
struct TutorialTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let accentHex: String
}

/// Full-screen tutorial overlay with multiple tips, shown once per page
struct TutorialOverlay: View {
    let pageName: String
    let tips: [TutorialTip]
    let onDismiss: () -> Void

    @State private var currentTip = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: 20) {
                    // Page indicator
                    HStack(spacing: 6) {
                        ForEach(0..<tips.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == currentTip ? Theme.accent : Theme.border)
                                .frame(width: 6, height: 6)
                                .animation(.easeOut, value: currentTip)
                        }
                    }

                    let tip = tips[currentTip]

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: tip.accentHex).opacity(0.15))
                            .frame(width: 64, height: 64)

                        Image(systemName: tip.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color(hex: tip.accentHex))
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                    // Text
                    VStack(spacing: 8) {
                        Text(tip.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(tip.body)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                    // Button
                    Button {
                        advance()
                    } label: {
                        Text(currentTip < tips.count - 1 ? "Next" : "Got it!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: tip.accentHex))
                            )
                    }

                    // Skip
                    if currentTip < tips.count - 1 {
                        Button {
                            HapticManager.light()
                            onDismiss()
                        } label: {
                            Text("Skip tutorial")
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.surface)
                        .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func advance() {
        HapticManager.light()
        if currentTip < tips.count - 1 {
            withAnimation(.spring(response: 0.3)) {
                appeared = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                currentTip += 1
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        } else {
            onDismiss()
        }
    }
}

// MARK: - Tutorial Definitions

enum Tutorials {

    static let home: [TutorialTip] = [
        TutorialTip(
            icon: "house.fill",
            title: "Welcome Home",
            body: "This is your daily dashboard. See your progress, today's habits, and weekly analytics all in one place.",
            accentHex: "39D353"
        ),
        TutorialTip(
            icon: "hand.draw.fill",
            title: "Swipe to Complete",
            body: "Swipe a habit right to mark it done. Swipe left to skip — your streak stays safe.",
            accentHex: "58A6FF"
        ),
        TutorialTip(
            icon: "number.circle.fill",
            title: "Log Quantities",
            body: "Some habits track amounts (like '20 pages'). Tap the number icon to log your progress.",
            accentHex: "8957E5"
        ),
        TutorialTip(
            icon: "quote.opening",
            title: "Daily Motivation",
            body: "A fresh quote every day to keep you inspired. Check back tomorrow for a new one.",
            accentHex: "FFA657"
        ),
    ]

    static let habits: [TutorialTip] = [
        TutorialTip(
            icon: "square.grid.3x3.fill",
            title: "Your Habits",
            body: "This is where you manage all your habits. Tap + to add new ones.",
            accentHex: "8957E5"
        ),
        TutorialTip(
            icon: "line.3.horizontal.decrease.circle",
            title: "Filter & Organize",
            body: "Switch between Active, Quit, Completed, and All tabs to find what you need.",
            accentHex: "58A6FF"
        ),
        TutorialTip(
            icon: "hand.tap.fill",
            title: "Long Press for Actions",
            body: "Long-press any habit for options: freeze streak, pause, or delete.",
            accentHex: "F78166"
        ),
        TutorialTip(
            icon: "snowflake",
            title: "Vacation Mode",
            body: "Going away? Freeze your streak for up to 7 days. Life happens — we've got you.",
            accentHex: "58A6FF"
        ),
    ]

    static let profile: [TutorialTip] = [
        TutorialTip(
            icon: "person.fill",
            title: "Your Profile",
            body: "Track your overall stats, unlock achievements, and see how each habit is performing.",
            accentHex: "D2A8FF"
        ),
        TutorialTip(
            icon: "square.and.arrow.up",
            title: "Export Your Data",
            body: "You own your data. Export everything as JSON or CSV from Settings below.",
            accentHex: "39D353"
        ),
        TutorialTip(
            icon: "trophy.fill",
            title: "Unlock Achievements",
            body: "Hit milestones to unlock badges. First Log, 7-Day Streak, 100 Logs, and more.",
            accentHex: "FFA657"
        ),
    ]

    static let communities: [TutorialTip] = [
        TutorialTip(
            icon: "person.3.fill",
            title: "Communities",
            body: "Join groups of people working on the same habits. Motivate each other and share progress.",
            accentHex: "8957E5"
        ),
        TutorialTip(
            icon: "chart.bar.xaxis",
            title: "Leaderboard & Chat",
            body: "See who's leading the streak race. Chat with your community to share tips and encouragement.",
            accentHex: "58A6FF"
        ),
        TutorialTip(
            icon: "crown.fill",
            title: "Create Your Own",
            body: "Reach a 21-day streak, earn 3 badges, or log 50 days to unlock community creation.",
            accentHex: "FFA657"
        ),
    ]
}

// MARK: - Preview

#Preview {
    TutorialOverlay(
        pageName: "home",
        tips: Tutorials.home,
        onDismiss: {}
    )
}
