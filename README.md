# HabitKit 🚀

A modern, gamified habit tracker for iOS built natively with **SwiftUI** and **SwiftData**. HabitKit turns daily routines into an engaging experience with streaks, dynamic badges, analytics, and community leaderboards.

![iOS 17+](https://img.shields.io/badge/iOS-17.0+-blue?logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-orange)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-lightgrey)

---

## ✨ Features

- **Gamified Tracking**: Earn emojis, badges, and streaks for completing habits.
- **Flexible Scheduling**: Daily, weekly, specific weekdays, or interval-based habits.
- **Quantifiable Goals**: Track numeric targets (e.g., "Drink 2L of water", "Read 20 pages").
- **Vacation Mode**: Pause habits without losing your hard-earned streaks.
- **Rich Analytics**: Heatmaps, completion rates, and historical logs.
- **Haptic Feedback**: Delightful tactile responses for every interaction.
- **Data Portability**: Export your habit data to JSON or CSV anytime.

## 🛠 Tech Stack

### Core App
- **UI Framework**: SwiftUI (iOS 17+)
- **Local Persistence**: SwiftData
- **Architecture**: MVVM (Model-View-ViewModel)
- **Haptics**: `UIImpactFeedbackGenerator` & `UINotificationFeedbackGenerator`

### Infrastructure Roadmap (In Progress)
*(See `goals.md` for full sprint tracking)*
- **Data Sync**: iCloud + CloudKit for native cross-device syncing.
- **Backend / Social**: Supabase (PostgreSQL + Realtime) for global communities, leaderboards, and chat.
- **Analytics**: PostHog for user behavior and telemetry.
- **Crash Reporting**: Firebase Crashlytics.
- **Monetization**: RevenueCat or Stripe checkout for Pro features (vacation mode, unlimited active habits).

---

## 💻 Getting Started

### Prerequisites
- **Xcode 15.0** or later.
- **macOS Sonoma** or later.
- An iOS Simulator running iOS 17.0+ or a physical device.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/axref-js/habitkit.git
   cd habitkit
   ```

2. **Open the project:**
   ```bash
   open habitkit.xcodeproj
   ```

3. **Build and Run:**
   - Select your desired Simulator (e.g., iPhone 15 Pro) from the target dropdown in Xcode.
   - Press **Cmd + R** (or click the Play button) to build and run the app.

---

## 📂 Project Structure

- **`/Models`**: Core datatypes (`Habit`, `HabitLog`, `Community`) and singletons (`AuthManager`, `ProManager`).
- **`/Views`**: SwiftUI interface components divided into tabs (Home, Habits, Community, Profile).
- **`/Theme`**: Centralized color palette and font configurations.
- **`/Utilities`**: Helper classes like `HapticManager`.
- **`HabitKitApp.swift`**: Main app entry point configuring the `ModelContainer`.

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
