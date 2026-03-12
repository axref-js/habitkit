//
//  ProManager.swift
//  habitkit
//
//  Pro subscription gating. Controls which features require payment.
//

import SwiftUI
import Combine
#if canImport(RevenueCat)
import RevenueCat
#endif
#if canImport(RevenueCatUI)
import RevenueCatUI
#endif

// MARK: - Pro Feature Definitions

enum ProFeature: String, CaseIterable, Identifiable {
    case unlimitedHabits     = "Unlimited Habits"
    case dataExport          = "Data Export"
    case vacationMode        = "Vacation Mode"
    case journaling          = "Reflective Journaling"
    case createCommunity     = "Create Communities"
    case advancedScheduling  = "Advanced Scheduling"
    case globalLeaderboard   = "Global Leaderboard"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .unlimitedHabits: return "infinity"
        case .dataExport: return "square.and.arrow.up"
        case .vacationMode: return "snowflake"
        case .journaling: return "text.book.closed"
        case .createCommunity: return "person.3.fill"
        case .advancedScheduling: return "calendar.badge.clock"
        case .globalLeaderboard: return "trophy.fill"
        }
    }

    var description: String {
        switch self {
        case .unlimitedHabits: return "Track as many habits as you want"
        case .dataExport: return "Export CSV & JSON data"
        case .vacationMode: return "Freeze streaks during breaks"
        case .journaling: return "Add notes to daily entries"
        case .createCommunity: return "Lead your own community"
        case .advancedScheduling: return "Interval & weekly schedules"
        case .globalLeaderboard: return "See your global ranking"
        }
    }

    var accentHex: String {
        switch self {
        case .unlimitedHabits: return "8957E5"
        case .dataExport: return "39D353"
        case .vacationMode: return "58A6FF"
        case .journaling: return "D2A8FF"
        case .createCommunity: return "F78166"
        case .advancedScheduling: return "FFA657"
        case .globalLeaderboard: return "FFA657"
        }
    }
}

// MARK: - Pro Manager

class ProManager: ObservableObject {
    static let shared = ProManager()

    @Published var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: "isProUser")
        }
    }
    
    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: "isProUser")
        
        #if canImport(RevenueCat)
        Task { @MainActor in
            for try await customerInfo in Purchases.shared.customerInfoStream {
                self.isPro = customerInfo.entitlements["habitkit Pro"]?.isActive == true
            }
        }
        #endif
    }

    /// Free tier limit
    static let freeHabitLimit = 5

    func isLocked(_ feature: ProFeature) -> Bool {
        return !isPro
    }

    func requirePro(_ feature: ProFeature, action: () -> Void) -> Bool {
        if isPro {
            action()
            return true
        }
        return false
    }
}

// MARK: - Pro Badge

struct ProBadge: View {
    var small = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: small ? 7 : 9, weight: .bold))
            Text("PRO")
                .font(.system(size: small ? 7 : 9, weight: .black, design: .monospaced))
        }
        .foregroundStyle(Color(hex: "FFA657"))
        .padding(.horizontal, small ? 4 : 6)
        .padding(.vertical, small ? 2 : 3)
        .background(
            Capsule()
                .fill(Color(hex: "FFA657").opacity(0.12))
                .overlay(Capsule().strokeBorder(Color(hex: "FFA657").opacity(0.3), lineWidth: 1))
        )
    }
}

// MARK: - Pro Paywall Sheet

struct ProPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var proManager = ProManager.shared

    var highlightedFeature: ProFeature?

    var body: some View {
        #if canImport(RevenueCatUI)
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { customerInfo in
                proManager.isPro = customerInfo.entitlements["habitkit Pro"]?.isActive == true
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                proManager.isPro = customerInfo.entitlements["habitkit Pro"]?.isActive == true
                if proManager.isPro { dismiss() }
            }
        #else
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "FFA657"), Color(hex: "F78166")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 72, height: 72)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }

                        Text("Upgrade to Pro")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)

                        Text("Unlock every feature. Build habits without limits.")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Feature list
                    VStack(spacing: 0) {
                        ForEach(ProFeature.allCases) { feature in
                            let isHighlighted = feature == highlightedFeature
                            HStack(spacing: 12) {
                                Image(systemName: feature.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: feature.accentHex))
                                    .frame(width: 28, height: 28)
                                    .background(Color(hex: feature.accentHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(feature.description)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(hex: feature.accentHex))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(isHighlighted ? Color(hex: feature.accentHex).opacity(0.05) : .clear)

                            if feature != ProFeature.allCases.last {
                                Divider().background(Theme.border)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Pricing
                    VStack(spacing: 12) {
                        // Annual
                        pricingButton(label: "Annual", price: "$29.99/year", perMonth: "$2.50/mo", bestValue: true) {
                            proManager.isPro = true
                            HapticManager.success()
                            dismiss()
                        }

                        // Monthly
                        pricingButton(label: "Monthly", price: "$4.99/month", perMonth: nil, bestValue: false) {
                            proManager.isPro = true
                            HapticManager.success()
                            dismiss()
                        }
                    }

                    // Restore
                    Button {
                        proManager.isPro = true
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Text("Restore Purchase")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        #endif
    }

    private func pricingButton(label: String, price: String, perMonth: String?, bestValue: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        if bestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.white.opacity(0.2)))
                        }
                    }
                    if let perMonth {
                        Text(perMonth)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Spacer()
                Text(price)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(bestValue
                          ? LinearGradient(colors: [Color(hex: "FFA657"), Color(hex: "F78166")], startPoint: .leading, endPoint: .trailing)
                          : LinearGradient(colors: [Theme.surfaceHover, Theme.surfaceHover], startPoint: .leading, endPoint: .trailing)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
