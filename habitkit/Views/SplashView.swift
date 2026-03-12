//
//  SplashView.swift
//  habitkit
//
//  Animated welcome screen on first launch.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var particlesVisible = false

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.accent.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .opacity(glowOpacity)
                .blur(radius: 60)

            // Floating particles
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Theme.accent.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 3...6))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -300...300)
                    )
                    .opacity(particlesVisible ? 1 : 0)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1.5...3.0))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: particlesVisible
                    )
            }

            VStack(spacing: 24) {
                // Animated logo
                ZStack {
                    // Outer ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    // Grid icon
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent, Color(hex: "2EA043")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                // Title
                VStack(spacing: 8) {
                    Text("HabitKit")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundStyle(Theme.textPrimary)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Build the life you want.\nOne square at a time.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                }
            }
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            withAnimation(.easeIn(duration: 0.8).delay(0.8)) {
                subtitleOpacity = 1.0
                glowOpacity = 1.0
            }

            withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
                particlesVisible = true
            }

            // Auto-advance after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
