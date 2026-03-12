//
//  Theme.swift
//  habitkit
//
//  Design system: "Functional Minimalist" — Linear meets GitHub.
//

import SwiftUI

// MARK: - Design Tokens

enum Theme {

    // MARK: Colors

    /// Deep background — GitHub-dark inspired
    static let background = Color(hex: "0D1117")

    /// Elevated card surface
    static let surface = Color(hex: "161B22")

    /// Slightly lifted surface for hover / active states
    static let surfaceHover = Color(hex: "1C2128")

    /// Borders & dividers
    static let border = Color(hex: "30363D")

    /// Primary text
    static let textPrimary = Color(hex: "E6EDF3")

    /// Secondary / muted text
    static let textSecondary = Color(hex: "8B949E")

    /// Tertiary / disabled text
    static let textTertiary = Color(hex: "484F58")

    /// Brand accent — vibrant emerald
    static let accent = Color(hex: "39D353")

    /// Brand gradient
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "39D353"), Color(hex: "2EA043")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Heatmap Ramp

    /// Empty cell — no activity
    static let heatmapEmpty = Color(hex: "161B22")

    /// 5-step intensity ramp (used when no custom accent is provided)
    static let heatmapRamp: [Color] = [
        Color(hex: "0E4429"),
        Color(hex: "006D32"),
        Color(hex: "26A641"),
        Color(hex: "39D353"),
    ]

    /// Generate a heatmap ramp from any accent hex
    static func heatmapRamp(for hex: String) -> [Color] {
        let base = Color(hex: hex)
        return [
            base.opacity(0.25),
            base.opacity(0.50),
            base.opacity(0.75),
            base,
        ]
    }

    /// Map a 0.0–1.0 value to a heatmap color
    static func heatmapColor(value: Double, accentHex: String) -> Color {
        if value <= 0 { return heatmapEmpty }
        let ramp = heatmapRamp(for: accentHex)
        let index = min(Int(value * Double(ramp.count)), ramp.count - 1)
        return ramp[index]
    }

    // MARK: Typography

    static let titleFont: Font = .system(size: 28, weight: .bold, design: .default)
    static let headlineFont: Font = .system(size: 17, weight: .semibold, design: .default)
    static let bodyFont: Font = .system(size: 15, weight: .regular, design: .default)
    static let captionFont: Font = .system(size: 12, weight: .medium, design: .monospaced)
    static let microFont: Font = .system(size: 10, weight: .medium, design: .monospaced)

    // MARK: Spacing & Radii

    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let gridSpacing: CGFloat = 3
    static let cellSize: CGFloat = 12

    // MARK: Shadows

    static let cardShadow: some ShapeStyle = Color.black.opacity(0.35)
}

// MARK: - Color+Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
