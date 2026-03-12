# HabitKit — Production Roadmap

Engineering-ordered checklist. Every service is **$0 at launch scale**. Steps include exact navigation paths so you know where every button is.

---

## 🔧 Sprint 1: Code & Build Hardening (Day 1)

> Before adding any services, make the existing app production-safe.

- [ ] **1.1** Remove all `fatalError()` and `try!` calls from non-preview code.
  - `StarterPack.swift` line 86: replace `try!` with `do/catch`.
  - `HabitListView.swift` preview: `try!` is fine here (preview only).
- [ ] **1.2** Set the production Bundle ID.
  - Xcode → click the **habitkit** project (blue icon, top of the file navigator) → **Targets** → **habitkit** → **General** tab → **Bundle Identifier** field → set to `com.axrf.habitkit`.
- [ ] **1.3** Set the app version and build number.
  - Same **General** tab → **Identity** section → **Version**: `1.0.0`, **Build**: `1`.
- [ ] **1.4** Add the App Icon.
  - Xcode file navigator → `Assets.xcassets` → `AppIcon` → drag your 1024×1024 icon into the **All Sizes** slot.
- [ ] **1.5** Set the Deployment Target.
  - Xcode → **habitkit** project → **Targets** → **General** → **Minimum Deployments** → set to `iOS 17.0`.
- [ ] **1.6** Switch build config to Release for testing.
  - Xcode top menu → **Product** → **Scheme** → **Edit Scheme…** → left sidebar: **Run** → **Info** tab → **Build Configuration** dropdown → select `Release`.

---

## ☁️ Sprint 2: iCloud Sync (Day 2–3)

> Users expect their habits to appear on all their Apple devices. This uses Apple's free CloudKit.

- [ ] **2.1** Enable iCloud capability in Xcode.
  - Xcode → click the **habitkit** project → **Targets** → **habitkit** → **Signing & Capabilities** tab → click the **+ Capability** button (top-left of the tab) → type "iCloud" in the search → double-click **iCloud**.
- [ ] **2.2** Enable CloudKit.
  - In the newly added iCloud section, check the **CloudKit** checkbox.
  - Under **Containers**, click the **+** button → enter `iCloud.com.yourname.habitkit` → click **OK**.
- [ ] **2.3** Update `habitkitApp.swift` to use CloudKit-backed ModelContainer.
  ```swift
  let config = ModelConfiguration(
      "HabitKit",
      schema: Schema([Habit.self, HabitLog.self]),
      cloudKitDatabase: .automatic   // ← this one line enables sync
  )
  let container = try ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
  ```
- [ ] **2.4** Add a `lastModified` field to `Habit.swift` for conflict resolution.
  ```swift
  var lastModified: Date = Date.now
  ```
  Update it in every mutation (`toggleToday`, `logQuantity`, `skipToday`).
- [ ] **2.5** Test sync.
  - Build & run on **two devices** (or Simulator + real device) signed into the **same Apple ID**.
  - Create a habit on device 1 → it should appear on device 2 within ~15 seconds.

---

## 💳 Sprint 3: RevenueCat Monetization (Day 4–6)

### Part A: App Store Connect Setup

- [ ] **3.1** Log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
- [ ] **3.2** Create the app record.
  - Top-left **blue +** button → **New App** → Platform: **iOS** → Name: `HabitKit` → Primary Language → Bundle ID: select the one from step 1.2 → SKU: `habitkit001` → **Create**.
- [ ] **3.3** Create In-App Purchase products.
  - Left sidebar → your app → **Monetization** (in the sidebar, below "Distribution") → **Subscriptions** → **+** button next to "Subscription Groups" → Group name: `HabitKit Pro` → **Create**.
  - Inside the group, click the **+** button next to "Subscriptions" → create each:
    - **Reference Name**: `Pro Monthly` → **Product ID**: `habitkit_pro_monthly` → **Subscription Duration** dropdown: `1 Month` → **Create** → **Subscription Prices** section: click **+** → choose currency and set **$2.99** → **Next** → **Create**.
    - Repeat for: `habitkit_pro_yearly` ($19.99, 1 Year) and `habitkit_pro_lifetime` (use a **Non-Consumable** In-App Purchase instead: Monetization → In-App Purchases → **+** → `habitkit_pro_lifetime`, $49.99).
- [ ] **3.4** Generate the In-App Purchase Key.
  - **Top menu bar** → **Users and Access** → left sidebar → **Integrations** → **In-App Purchase** tab → **Generate In-App Purchase Key** button → Name: `RevenueCat` → **Generate** → click **Download** to save the `.p8` file → note the **Key ID** and **Issuer ID** shown on the page.

### Part B: RevenueCat Dashboard Setup

- [ ] **3.5** Go to [app.revenuecat.com](https://app.revenuecat.com) → **Create New Project** (button in top-right) → Name: `HabitKit` → **Create Project**.
- [ ] **3.6** Add Apple App Store app.
  - Inside the project, click **+ New** (under "Apps") → select **Apple App Store** → fill in:
    - **App name**: `HabitKit`
    - **Apple Bundle ID**: `com.yourname.habitkit`
    - **In-App Purchase Key**: upload the `.p8` file from step 3.4
    - **In-App Purchase Key ID**: from step 3.4
    - **Issuer ID**: from step 3.4
    - **App-Specific Shared Secret**: get this from App Store Connect → your app → **General** → **App Information** → scroll to **App-Specific Shared Secret** → **Manage** → **Generate** → copy it → paste here.
  - Click **Save Changes**.
- [ ] **3.7** Import products.
  - Left sidebar → **Products and Pricing** → **Products** → **+ New** → **Product Identifier**: `habitkit_pro_monthly` → **App**: HabitKit → **Save** → Repeat for `_yearly` and `_lifetime`.
- [ ] **3.8** Create Entitlement.
  - Left sidebar → **Products and Pricing** → **Entitlements** → **+ New** → **Identifier**: `pro` → **Save** → click into `pro` → **Attach** button at top → select all 3 products → **Add**.
- [ ] **3.9** Create Offering.
  - Left sidebar → **Products and Pricing** → **Offerings** → **+ New** → **Identifier**: `default` → **Save** → click into `default` → **+ New Package** for each:
    - Package: `$rc_monthly` → Product: `habitkit_pro_monthly`
    - Package: `$rc_annual` → Product: `habitkit_pro_yearly`
    - Package: `$rc_lifetime` → Product: `habitkit_pro_lifetime`
- [ ] **3.10** Copy API Key.
  - Left sidebar → **API Keys** → under **Public app-specific API keys** → copy the key starting with `appl_...`.

### Part C: Xcode Integration

- [ ] **3.11** Install RevenueCat SDK.
  - Xcode top menu → **File** → **Add Package Dependencies…** → paste `https://github.com/RevenueCat/purchases-ios-spm.git` into the search bar → click **Add Package** → check **RevenueCat** and **RevenueCatUI** → **Add Package**.
- [ ] **3.12** Initialize in `habitkitApp.swift`:
  ```swift
  import RevenueCat
  init() {
      Purchases.configure(withAPIKey: "appl_YOUR_KEY")
  }
  ```
- [ ] **3.13** Update `ProManager.swift` — replace mock logic with real entitlement check (code in `revenuecat.md`).
- [ ] **3.14** Present the paywall using RevenueCatUI:
  ```swift
  import RevenueCatUI
  .sheet(isPresented: $showPaywall) {
      PaywallView()
          .onPurchaseCompleted { info in
              ProManager.shared.isPro = info.entitlements["pro"]?.isActive == true
          }
  }
  ```
- [ ] **3.15** Test in Sandbox.
  - App Store Connect → **Users and Access** → **Sandbox** tab (top bar) → **Sandbox Apple Accounts** section → **+** button → create a test account → sign into this account on your test device under **Settings → App Store → Sandbox Account** → run the app and try purchasing.

---

## 🔥 Sprint 4: Firebase Crashlytics (Day 7)

> See crash reports with stack traces. Always free.

- [ ] **4.1** Go to [console.firebase.google.com](https://console.firebase.google.com) → **Create a project** (blue button) → Name: `HabitKit` → **Continue** → disable Google Analytics (optional, we use PostHog) → **Create project**.
- [ ] **4.2** Add iOS app.
  - On the project overview page, click the **iOS+** button (circle with iOS icon) → **Apple bundle ID**: `com.yourname.habitkit` → **App nickname**: `HabitKit` → **Register app**.
  - **Download `GoogleService-Info.plist`** → drag it into Xcode's file navigator, drop it right under the `habitkit` folder → check "Copy items if needed" and target **habitkit** → **Finish**.
  - Skip the remaining Firebase setup wizard steps (we'll use SPM instead of CocoaPods).
- [ ] **4.3** Install Firebase SDK.
  - Xcode → **File** → **Add Package Dependencies…** → paste `https://github.com/firebase/firebase-ios-sdk.git` → **Add Package** → in the library picker, check **only** `FirebaseCrashlytics` → **Add Package**.
- [ ] **4.4** Add dSYM upload script.
  - Xcode → **habitkit** target → **Build Phases** tab → click **+** (top-left) → **New Run Script Phase** → drag it **after** "Compile Sources" → paste:
    ```bash
    "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
    ```
  - Uncheck "Based on dependency analysis" checkbox.
- [ ] **4.5** Enable dSYM generation.
  - **Build Settings** tab → search for `DEBUG_INFORMATION_FORMAT` → set **Release** row to `DWARF with dSYM File`.
- [ ] **4.6** Initialize in `habitkitApp.swift`:
  ```swift
  import FirebaseCore
  init() {
      FirebaseApp.configure()
  }
  ```
- [ ] **4.7** Test: add `fatalError("Crashlytics test")` somewhere, run the app, trigger it, relaunch the app, then check **Firebase Console → left sidebar → Crashlytics** → your crash should appear within 5 minutes.

---

## 📈 Sprint 5: PostHog Analytics (Day 8)

> Understand user behavior. Free for 1M events/month.

- [ ] **5.1** Create account at [posthog.com](https://posthog.com) → after signup, you'll land on the **Getting Started** page → copy your **API Key** (starts with `phc_`) and **Host** URL.
- [ ] **5.2** Install SDK.
  - Xcode → **File** → **Add Package Dependencies…** → paste `https://github.com/PostHog/posthog-ios.git` → **Add Package** → select `PostHog` → **Add Package**.
- [ ] **5.3** Initialize in `habitkitApp.swift`:
  ```swift
  import PostHog
  init() {
      let config = PostHogConfig(apiKey: "phc_YOUR_KEY", host: "https://us.i.posthog.com")
      PostHogSDK.shared.setup(config)
  }
  ```
- [ ] **5.4** Add event tracking calls:
  - `LoginView.swift` → inside `handleLogin()`, after `authManager.login(...)`:
    ```swift
    PostHogSDK.shared.capture("user_logged_in")
    ```
  - `SignupView.swift` → inside `handleSignup()`, after `authManager.signup(...)`:
    ```swift
    PostHogSDK.shared.capture("user_signed_up")
    ```
  - `Habit.swift` → inside `toggleToday(context:)`, after inserting a new log:
    ```swift
    PostHogSDK.shared.capture("habit_logged", properties: ["habit_name": name, "streak": streak])
    ```
  - `ProPaywallSheet.swift` → add `.onAppear`:
    ```swift
    .onAppear { PostHogSDK.shared.capture("paywall_viewed") }
    ```
- [ ] **5.5** Identify users after login:
  ```swift
  PostHogSDK.shared.identify(email, userProperties: ["name": userName])
  ```
- [ ] **5.6** Build a dashboard.
  - PostHog web app → left sidebar → **Dashboards** → **+ New dashboard** → **Add insight** (blue button) → choose **Funnel** → add steps: `user_signed_up` → `habit_logged` → **Save**.

---

## 🌐 Sprint 6: Supabase Communities & Leaderboard (Day 9–12)

> Public shared data (chat, leaderboard). Free for 50K MAU.

- [ ] **6.1** Go to [supabase.com](https://supabase.com) → **Start your project** (green button) → sign in with GitHub → **New Project** → Name: `habitkit` → set a database password → Region: closest to you → **Create new project** → wait ~2 minutes for provisioning.
- [ ] **6.2** Get your credentials.
  - Left sidebar → **Project Settings** (gear icon, bottom) → **API** → copy:
    - **Project URL** (looks like `https://xxxx.supabase.co`)
    - **anon public** key (under "Project API keys")
- [ ] **6.3** Create tables.
  - Left sidebar → **SQL Editor** (terminal icon) → **+ New query** → paste and run each:
  ```sql
  CREATE TABLE communities (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      name TEXT NOT NULL,
      emoji TEXT DEFAULT '🏠',
      color_hex TEXT DEFAULT '39D353',
      focus TEXT DEFAULT '',
      creator_id UUID REFERENCES auth.users(id),
      discord_link TEXT,
      reddit_link TEXT,
      created_at TIMESTAMPTZ DEFAULT now()
  );

  CREATE TABLE community_members (
      community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
      user_id UUID REFERENCES auth.users(id),
      joined_at TIMESTAMPTZ DEFAULT now(),
      PRIMARY KEY (community_id, user_id)
  );

  CREATE TABLE community_messages (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
      user_id UUID REFERENCES auth.users(id),
      display_name TEXT DEFAULT 'Anonymous',
      text TEXT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
  );

  CREATE TABLE leaderboard_entries (
      user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
      display_name TEXT NOT NULL,
      streak INT DEFAULT 0,
      total_logs INT DEFAULT 0,
      updated_at TIMESTAMPTZ DEFAULT now()
  );
  ```
- [ ] **6.4** Enable Row Level Security.
  - Same SQL Editor → new query:
  ```sql
  ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
  ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;
  ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;
  ALTER TABLE leaderboard_entries ENABLE ROW LEVEL SECURITY;

  -- Everyone can read
  CREATE POLICY "read_communities" ON communities FOR SELECT USING (true);
  CREATE POLICY "read_members" ON community_members FOR SELECT USING (true);
  CREATE POLICY "read_messages" ON community_messages FOR SELECT USING (true);
  CREATE POLICY "read_leaderboard" ON leaderboard_entries FOR SELECT USING (true);

  -- Only authenticated users can write their own data
  CREATE POLICY "insert_communities" ON communities FOR INSERT WITH CHECK (auth.uid() = creator_id);
  CREATE POLICY "insert_members" ON community_members FOR INSERT WITH CHECK (auth.uid() = user_id);
  CREATE POLICY "insert_messages" ON community_messages FOR INSERT WITH CHECK (auth.uid() = user_id);
  CREATE POLICY "upsert_leaderboard" ON leaderboard_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
  CREATE POLICY "update_leaderboard" ON leaderboard_entries FOR UPDATE USING (auth.uid() = user_id);
  ```
- [ ] **6.5** Enable Realtime for chat.
  - Left sidebar → **Database** (cylinder icon) → **Replication** → find `community_messages` → toggle the **Insert** switch **ON**.
- [ ] **6.6** Install Supabase SDK in Xcode.
  - **File** → **Add Package Dependencies…** → paste `https://github.com/supabase-community/supabase-swift.git` → **Add Package** → select `Supabase` → **Add Package**.
- [ ] **6.7** Create `SupabaseManager.swift` in `habitkit/Utilities/`:
  ```swift
  import Supabase

  final class SupabaseManager {
      static let shared = SupabaseManager()
      let client: SupabaseClient

      private init() {
          client = SupabaseClient(
              supabaseURL: URL(string: "https://YOUR_PROJECT.supabase.co")!,
              supabaseKey: "YOUR_ANON_KEY"
          )
      }
  }
  ```
- [ ] **6.8** Wire up `AuthManager` to Supabase Auth instead of `UserDefaults`.
- [ ] **6.9** Replace local mock data in `CommunityListView` and `LeaderboardView` with Supabase fetches.

---

## 🚀 Sprint 7: App Store Submission (Day 13–14)

- [ ] **7.1** App Store Connect → your app → **App Information** → fill in:
  - **Subtitle**: e.g., "Build habits. Break streaks."
  - **Category**: Health & Fitness
  - **Content Rights**: confirm you own all content
  - **Age Rating**: tap **Edit** → answer the questionnaire
- [ ] **7.2** Prepare screenshots.
  - Run the app on iPhone 15 Pro Max (6.7") and iPhone SE (5.5") simulators → take at least **3 screenshots** per size → upload under **App Store** tab → **App Preview and Screenshots**.
- [ ] **7.3** Write the App Store description.
  - **Promotional Text** (can change anytime, 170 chars)
  - **Description** (only changes with new version, 4000 chars)
  - **Keywords** (100 chars, comma separated): `habit,tracker,streak,routine,goals,health,productivity`
- [ ] **7.4** Set the Privacy Policy URL.
  - Required field under **App Information** → **Privacy Policy URL**. You can host a simple page on Notion or GitHub Pages.
- [ ] **7.5** Archive and upload.
  - Xcode → **Product** menu → **Archive** → wait for build → in the **Organizer** window that opens, click **Distribute App** → **App Store Connect** → **Upload** → **Next** through defaults → **Upload**.
- [ ] **7.6** Submit for review.
  - Back in App Store Connect → **App Store** tab → your app version → scroll to **Build** section → click **+** → select the uploaded build → fill in **What's New** → click **Submit for Review** (top-right blue button).
