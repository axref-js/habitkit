HabitKit — Advanced Features
✅ Phase 1–2: Foundation, Onboarding, Dashboard
 Core models, theme, heatmap, habit cards, splash, onboarding, paywall, tabs, profile
✅ Phase 3: Core Experience
 Flexible scheduling (daily/specificDays/timesPerWeek/interval)
 Quantifiable goals (goalValue, goalUnit, loggedAmount)
 Swipe gestures (right=complete, left=skip)
 Smart reminders (reminderEnabled, hour, minute)
✅ Phase 4: Psychology & Motivation
 Quit habits (build/quit type, days-since counter)
 Reflective journaling (note field on HabitLog)
 Vacation mode (freeze streak 1–7 days)
✅ Phase 5: Advanced
 Data export (JSON + CSV via share sheet)
 Per-page tutorials (Home, Habits, Profile, Communities)
 Profile customization (photo, bio, earned badges)
✅ Phase 6: Communities
 SwiftData models (Community, CommunityMember, CommunityMessage)
 Leadership requirements (21-day streak OR 3+ badges OR 50+ logs)
 Browse & Discover communities
 Join / Leave communities
 Create community (form with emoji/color/focus picker)
 Community detail: Chat (message bubbles, input bar)
 Community detail: Leaderboard (streak-ranked, gold/silver/bronze)
 Community detail: Members list
 Member public profile sheet (stats, badges, activity)
✅ Phase 7: Global Leaderboard & Pro Features
 ProManager (Singleton for tracking isProUser and gating features)
 ProPaywallSheet (Displays required features and annual/monthly pricing)
 Feature gating: unlimited habits, data export, vacation mode, journaling, community creation, advanced scheduling
 Global LeaderboardView with Olympic podium design (Gold/Silver/Bronze)
 Simulated global user competition dataset
 Navigation to Global Leaderboard from Profile
✅ Phase 8: Authentication & Community Expansion
 AuthManager created to handle application entry via UserDefaults
 LoginView and SignupView created with robust UI forms
 Added discordLink and redditLink optional properties to Community model
 Integrated link inputs in CreateCommunityView
 Added "Log Out" button under settings in ProfileView

Comment
⌥⌘M

---

# RevenueCat Integration Guide (SwiftUI)

This guide walks you through integrating RevenueCat into HabitKit to manage your "Pro" subscriptions instead of Stripe (which is usually for web or cross-platform). iOS requires using Apple's In-App Purchases, and RevenueCat is the best wrapper for it.

## 1. App Store Connect Setup
1. Log in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Create your App record for HabitKit.
3. Go to **Features -> In-App Purchases** and create your subscription products (e.g., `habitkit_pro_monthly`, `habitkit_pro_yearly`).
4. Generate an **In-App Purchase Key** under Users and Access -> Keys -> In-App Purchase. Download the `.p8` file.

## 2. RevenueCat Dashboard Setup
1. Create an account on [RevenueCat](https://www.revenuecat.com/).
2. Create a new Project called **HabitKit**.
3. Add an **Apple App Store** App to the project. Provide your Bundle ID and upload the `.p8` In-App Purchase Key.
4. Go to **Products and Pricing -> Products** and import your App Store products (`habitkit_pro_monthly`, etc.).
5. Go to **Entitlements** and create an entitlement named `pro`. Attach your imported products to this entitlement.
6. Go to **Offerings** and create a new offering named `default`. Add your products to this offering.
7. Go to **API Keys** and copy your **Public App-Specific API Key** (starts with `appl_...`).

## 3. Install the SDK
1. Open Xcode.
2. Go to `File -> Add Package Dependencies...`
3. Enter `https://github.com/RevenueCat/purchases-ios-spm.git`
4. Add the **RevenueCat** and **RevenueCatUI** (if using their pre-built paywalls) libraries to your HabitKit target.

## 4. Initialize RevenueCat in Code
In your `habitkitApp.swift`, configure the SDK:
```swift
import SwiftUI
import RevenueCat

@main
struct habitkitApp: App {
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_YOUR_REVENUECAT_API_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
```

## 5. Update `ProManager` for Entitlements
Modify your existing `ProManager` to read from RevenueCat instead of a local toggle:

```swift
import RevenueCat

class ProManager: ObservableObject {
    static let shared = ProManager()
    @Published var isPro: Bool = false
    
    private init() {
        checkSubscriptionStatus()
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let customerInfo {
                DispatchQueue.main.async {
                    self.isPro = customerInfo.entitlements["pro"]?.isActive == true
                }
            }
        }
    }
    
    func purchase(package: Package, completion: @escaping (Bool) -> Void) {
        Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
            if let customerInfo, customerInfo.entitlements["pro"]?.isActive == true {
                DispatchQueue.main.async {
                    self.isPro = true
                }
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
```

## 6. Build the Paywall (`ProPaywallSheet`)
You can use RevenueCat's Paywalls feature directly, or build a custom one by fetching the current default Offering:

```swift
import RevenueCatUI // Easiest way!

struct ProPaywallWrapper: View {
    var body: some View {
        PaywallView() // RevenueCat automatically generates a beautiful paywall based on your Dashboard config
            .onPurchaseCompleted { customerInfo in
                ProManager.shared.isPro = customerInfo.entitlements["pro"]?.isActive == true
            }
    }
}
```

If you prefer your custom UI, fetch packages via `Purchases.shared.getOfferings` and present them to the user.
