# Theodore — Dev Environment Setup

## What's in this folder

```
Theodore/
├── App/
│   └── TheodoreApp.swift          ← App entry + SwiftData container
├── Models/
│   ├── Book.swift                 ← SwiftData model
│   ├── Chapter.swift              ← SwiftData model
│   ├── Entry.swift                ← SwiftData model (photo + poem + prose)
│   └── ConversationMessage.swift  ← SwiftData model
├── Services/
│   ├── TheodoreService.swift      ← Claude API, streaming, chapter generation
│   ├── PhotoLibraryService.swift  ← PhotoKit, permissions, thumbnails
│   ├── ClusteringService.swift    ← Groups photos into chapter candidates
│   └── SubscriptionService.swift  ← StoreKit 2, Theodore+
├── ViewModels/
│   ├── BookViewModel.swift        ← Gallery reading, chapter creation
│   └── TheodoreViewModel.swift    ← Chat, streaming text
├── Views/
│   ├── RootView.swift             ← Onboarding gate
│   ├── Onboarding/
│   │   └── OnboardingView.swift   ← Splash → Reading → Proposals
│   ├── Book/
│   │   ├── BookLibraryView.swift  ← My Book screen
│   │   └── ChapterReadingView.swift ← Reading experience
│   ├── Chat/
│   │   └── TheodoreChatView.swift ← Theodore conversation
│   └── Components/
│       ├── DesignTokens.swift     ← All colours + fonts (matches Figma)
│       └── TheodoreAvatar.swift   ← Avatar, MessageBubble, TypingIndicator
├── Resources/
│   └── PrivacyInfo.xcprivacy     ← Required by Apple for Photos + network
└── Proxy/
    ├── worker.js                  ← Cloudflare Worker (API proxy)
    └── wrangler.toml              ← Worker config
```

---

## Step 1 — Create the Xcode project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Fill in:
   - **Product Name:** Theodore
   - **Bundle Identifier:** `com.yourname.theodore`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None ← important, we handle SwiftData manually
4. Choose a location and click Create

---

## Step 2 — Add source files

1. Delete the auto-generated `ContentView.swift`
2. Drag the folders from this package into your Xcode project:
   - `App/`, `Models/`, `Services/`, `ViewModels/`, `Views/`, `Resources/`
3. Make sure **"Copy items if needed"** is checked
4. Add all files to your app target

---

## Step 3 — Info.plist permissions

Add these keys to your **Info.plist** (or via target → Info tab):

| Key | Value |
|-----|-------|
| `NSPhotoLibraryUsageDescription` | Theodore reads your photos to find the stories in them. |
| `NSLocationWhenInUseUsageDescription` | Location helps Theodore name the places in your photos. |

---

## Step 4 — Deploy the API proxy

Never put your Claude API key in the app. Deploy the Cloudflare Worker first.

```bash
# Install Wrangler (Cloudflare CLI)
npm install -g wrangler

# Login
wrangler login

# Go to the Proxy folder
cd Theodore/Proxy

# Set your API key as a secret (paste when prompted)
wrangler secret put ANTHROPIC_API_KEY

# Deploy
wrangler deploy
```

Copy the deployed URL (e.g. `https://theodore-proxy.yourname.workers.dev`).

Open `Services/TheodoreService.swift` and replace:
```swift
static let proxyURL = URL(string: "https://theodore-proxy.YOUR-SUBDOMAIN.workers.dev/chat")\!
```

---

## Step 5 — Swift Package dependencies

In Xcode: **File → Add Package Dependencies**

Add these two:

| Package | URL | Purpose |
|---------|-----|---------|
| RevenueCat | `https://github.com/RevenueCat/purchases-ios` | Subscription management |
| *(optional)* SDWebImageSwiftUI | `https://github.com/SDWebImage/SDWebImageSwiftUI` | Async image loading |

> **Note:** `SubscriptionService.swift` uses raw StoreKit 2 as a fallback.
> Replace the purchase logic with RevenueCat's `Purchases.shared.purchase(package:)`
> for production — it handles edge cases you don't want to debug yourself.

---

## Step 6 — App Store Connect setup

Before testing subscriptions on a real device:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create a new app with bundle ID `com.yourname.theodore`
3. Add an **In-App Purchase → Auto-Renewable Subscription:**
   - Reference Name: `Theodore+ Annual`
   - Product ID: `com.yourname.theodore.annual` ← must match `SubscriptionService.swift`
   - Duration: 1 Year
   - Price: $29.99

---

## Step 7 — Build and run

```
Cmd+R → Select your iPhone simulator or device
```

First launch will show the onboarding screen. Grant photo access → Theodore reads the gallery → chapter proposals appear.

---

## Architecture decisions

**Why SwiftData over Core Data?**
SwiftData is cleaner, fewer files, native `@Model` macros, and the app targets iOS 17+. If you need iOS 16 support, swap every `@Model` class for a Core Data entity — the service layer doesn't change.

**Why a Cloudflare Worker over a backend?**
Zero infrastructure. Free tier handles thousands of requests/month. Deploys in 30 seconds. For v1, this is all you need. If you need user accounts or server-side caching later, migrate to a proper backend.

**Why not stream on device directly to the Claude API?**
The API key would be exposed in the binary. Anyone with a jailbroken device could extract it, rack up your bill, and there's nothing you could do. The proxy costs nothing and prevents that entirely.

**Why StoreKit 2 instead of just RevenueCat?**
The `SubscriptionService.swift` is a clean StoreKit 2 implementation that works without any dependencies. Switch to RevenueCat when you're ready for analytics, webhooks, and cross-platform support — the interface is identical.

---

## What's next to build

The scaffolding is complete. The remaining implementation work:

1. **`AsyncPhotoView`** — a SwiftUI view that loads a PHAsset as an image (replace the `Rectangle()` placeholder in `ChapterReadingView`)
2. **Photo → Claude Vision** — in `TheodoreViewModel.generateInitialChapter`, fetch the base64 image from `PhotoLibraryService.base64(for:)` and pass it as a vision content block in the API request
3. **Entry parsing** — parse Theodore's generated chapter text into discrete `Entry` objects (poem + prose per photo)
4. **Paywall screen** — a simple sheet that appears when `SubscriptionService.canCreateChapter` returns false
5. **Notifications** — local `UNUserNotificationCenter` nudge when 10+ new photos accumulate

*"I'm never lonely." — Her, 2013*
