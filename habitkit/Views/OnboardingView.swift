//
//  OnboardingView.swift
//  habitkit
//
//  Multi-step onboarding: emotional conviction → user data → pro paywall.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var slideDirection: Edge = .trailing

    // User data collected during onboarding — persisted
    @AppStorage("userName") private var userName = ""
    @State private var selectedGoal = ""
    @State private var selectedStruggle = ""
    @State private var dailyCommitment = 1

    let onComplete: () -> Void

    private let totalSteps = 7

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.top, 8)

                // Step content
                TabView(selection: $currentStep) {
                    // -- Emotional conviction screens --
                    emotionStep1.tag(0)
                    emotionStep2.tag(1)
                    emotionStep3.tag(2)

                    // -- User data screens --
                    nameStep.tag(3)
                    goalStep.tag(4)
                    struggleStep.tag(5)

                    // -- Paywall --
                    paywallStep.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.border)
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * (CGFloat(currentStep + 1) / CGFloat(totalSteps)), height: 3)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 24)
    }

    // MARK: - Emotion Step 1: The Hook

    private var emotionStep1: some View {
        onboardingPage(
            icon: "brain.head.profile",
            iconColor: "8957E5",
            title: "Your brain is\nalready wired\nfor habits.",
            body: "40% of your daily actions aren't decisions—they're habits. The question isn't *whether* you build them. It's *which ones* you choose.",
            buttonText: "Tell me more"
        ) {
            withAnimation { currentStep = 1 }
        }
    }

    // MARK: - Emotion Step 2: The Pain

    private var emotionStep2: some View {
        onboardingPage(
            icon: "chart.line.downtrend.xyaxis",
            iconColor: "FF7B72",
            title: "Motivation fades.\nSystems don't.",
            body: "Research shows motivation drops 80% after week two. That's not a character flaw—it's biology. You don't need more willpower. You need a system that makes progress *visible*.",
            buttonText: "What's the system?"
        ) {
            withAnimation { currentStep = 2 }
        }
    }

    // MARK: - Emotion Step 3: The Solution

    private var emotionStep3: some View {
        onboardingPage(
            icon: "square.grid.3x3.fill",
            iconColor: "39D353",
            title: "One green square\nchanges everything.",
            body: "Every filled square is proof that you showed up. Streaks create accountability. The grid creates clarity. Consistency creates the person you want to be.",
            buttonText: "Let's set you up"
        ) {
            withAnimation { currentStep = 3 }
        }
    }

    // MARK: - Name Step

    private var nameStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("👋")
                    .font(.system(size: 48))

                Text("What should we\ncall you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Just your first name is perfect.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            TextField("Your name", text: $userName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Theme.border, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40)

            Spacer()

            continueButton(disabled: userName.trimmingCharacters(in: .whitespaces).isEmpty) {
                HapticManager.medium()
                withAnimation { currentStep = 4 }
            }
        }
        .padding(24)
    }

    // MARK: - Goal Step

    private var goalStep: some View {
        let goals = [
            ("🏋️", "Get healthier"),
            ("🧠", "Sharpen my mind"),
            ("⏰", "Be more productive"),
            ("😌", "Reduce stress"),
            ("📈", "Build discipline"),
            ("✨", "Complete reinvention"),
        ]

        return VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text("What's driving you\nright now, \(userName.isEmpty ? "friend" : userName)?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Pick the one that resonates most.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 10) {
                ForEach(goals, id: \.1) { emoji, label in
                    selectionRow(emoji: emoji, label: label, isSelected: selectedGoal == label) {
                        selectedGoal = label
                        HapticManager.light()
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            continueButton(disabled: selectedGoal.isEmpty) {
                HapticManager.medium()
                withAnimation { currentStep = 5 }
            }
        }
        .padding(24)
    }

    // MARK: - Struggle Step

    private var struggleStep: some View {
        let struggles = [
            ("📱", "I get distracted easily"),
            ("😴", "I can't stay consistent"),
            ("🤷", "I don't know where to start"),
            ("⏳", "I never have enough time"),
            ("📊", "I lose track of progress"),
        ]

        return VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text("What usually\ngets in your way?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("No judgment. We've all been there.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 10) {
                ForEach(struggles, id: \.1) { emoji, label in
                    selectionRow(emoji: emoji, label: label, isSelected: selectedStruggle == label) {
                        selectedStruggle = label
                        HapticManager.light()
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            continueButton(disabled: selectedStruggle.isEmpty) {
                HapticManager.medium()
                withAnimation { currentStep = 6 }
            }
        }
        .padding(24)
    }

    // MARK: - Paywall

    private var paywallStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("🚀")
                        .font(.system(size: 44))

                    Text("You're ready, \(userName.isEmpty ? "friend" : userName).")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Unlock everything. No limits.")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 40)

                // Feature comparison
                VStack(spacing: 0) {
                    featureRow("Unlimited habits", free: "3", pro: "∞")
                    featureRow("Heatmap history", free: "4 weeks", pro: "Forever")
                    featureRow("Widgets", free: false, pro: true)
                    featureRow("Custom colors", free: false, pro: true)
                    featureRow("Detailed analytics", free: false, pro: true)
                    featureRow("Export data", free: false, pro: true)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.surface)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Pricing cards
                VStack(spacing: 12) {
                    // Annual (best value)
                    pricingCard(
                        title: "Annual",
                        price: "$29.99",
                        period: "/year",
                        subtitle: "Just $2.50/month — save 58%",
                        isPopular: true
                    )

                    // Monthly
                    pricingCard(
                        title: "Monthly",
                        price: "$5.99",
                        period: "/month",
                        subtitle: "Cancel anytime",
                        isPopular: false
                    )

                    // Lifetime
                    pricingCard(
                        title: "Lifetime",
                        price: "$79.99",
                        period: "",
                        subtitle: "One-time purchase. Yours forever.",
                        isPopular: false
                    )
                }

                // CTA button
                Button {
                    HapticManager.success()
                    // In production, trigger StoreKit purchase here
                    onComplete()
                } label: {
                    Text("Start Free Trial")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Theme.accent, Color(hex: "2EA043")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("7-day free trial, then $29.99/year")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)

                // Skip button
                Button {
                    onComplete()
                } label: {
                    Text("Maybe later")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)
                        .underline()
                }
                .padding(.bottom, 32)

                // Legal
                HStack(spacing: 16) {
                    Button("Terms") {}
                        .font(Theme.microFont)
                        .foregroundStyle(Theme.textTertiary)
                    Button("Privacy") {}
                        .font(Theme.microFont)
                        .foregroundStyle(Theme.textTertiary)
                    Button("Restore") {}
                        .font(Theme.microFont)
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Reusable Components

    private func onboardingPage(
        icon: String,
        iconColor: String,
        title: String,
        body: String,
        buttonText: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: iconColor).opacity(0.12))
                    .frame(width: 88, height: 88)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color(hex: iconColor))
            }

            // Text
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text(body)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            Spacer()

            continueButton(label: buttonText) {
                HapticManager.medium()
                action()
            }
        }
        .padding(24)
    }

    private func continueButton(label: String = "Continue", disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(disabled ? Theme.textTertiary : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(disabled ? Theme.surface : Theme.accent)
                )
        }
        .disabled(disabled)
    }

    private func selectionRow(emoji: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 22))

                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Theme.accent : Theme.border, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.accent.opacity(0.08) : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Paywall Components

    private func featureRow(_ feature: String, free: String, pro: String) -> some View {
        HStack {
            Text(feature)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(free)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 60)

            Text(pro)
                .font(Theme.captionFont)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.accent)
                .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func featureRow(_ feature: String, free: Bool, pro: Bool) -> some View {
        HStack {
            Text(feature)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: free ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 16))
                .foregroundStyle(free ? Theme.accent : Theme.textTertiary)
                .frame(width: 60)

            Image(systemName: pro ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 16))
                .foregroundStyle(pro ? Theme.accent : Theme.textTertiary)
                .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func pricingCard(title: String, price: String, period: String, subtitle: String, isPopular: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)

                    if isPopular {
                        Text("BEST VALUE")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.accent, in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(price)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(period)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isPopular ? Theme.accent : Theme.border, lineWidth: isPopular ? 1.5 : 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
