//
//  HapticManager.swift
//  habitkit
//
//  Thin wrapper around UIKit haptic feedback generators.
//

import UIKit

enum HapticManager {

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Subtle tap — hover / selection
    static func light() {
        lightGenerator.impactOccurred()
    }

    /// Firm tap — toggle / confirm action
    static func medium() {
        mediumGenerator.impactOccurred()
    }

    /// Heavy tap — streak milestone
    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    /// Success notification — habit completed
    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification
    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
}
