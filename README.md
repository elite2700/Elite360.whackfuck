# Elite360.Whackfuck

> **The premium social golf companion for serious golfers** — competitive games, money management, analytics, and AI assistance.

Elite360.Whackfuck is an iOS-only app built with **Swift/SwiftUI** (iOS 17+) and **Firebase**, designed for groups of friends or leagues who play for stakes while providing tools for personal improvement.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | SwiftUI (iOS 17+) |
| **Backend** | Firebase (Auth, Firestore, Cloud Functions, Storage) |
| **AI** | Google Generative AI (Gemini) |
| **Location** | Core Location + MapKit |
| **Payments** | RevenueCat (StoreKit 2) |
| **Package Manager** | Swift Package Manager |

## Project Structure

```
Elite360Whackfuck/
├── App/                          # App entry point, root navigation
│   ├── Elite360WhackfuckApp.swift
│   ├── RootView.swift
│   └── MainTabView.swift
├── Models/                       # Data models (Firestore Codable)
│   ├── UserProfile.swift         # User, friends, groups
│   ├── GolfCourse.swift          # Course & hole data
│   ├── GolfRound.swift           # Round, scorecard, hole scores
│   ├── GameModels.swift          # All 14 game formats + custom
│   ├── MoneyModels.swift         # Pot, ledger, settlements
│   ├── HandicapModels.swift      # WHS handicap records
│   ├── AnalyticsModels.swift     # Stats, trends, leaderboards
│   └── AICaddyModels.swift       # AI advice, shot context
├── Services/                     # Business logic layer
│   ├── FirestoreService.swift    # Generic Firestore CRUD + listeners
│   ├── AuthService.swift         # Firebase Auth (Email, Apple, Google)
│   ├── HandicapService.swift     # USGA/WHS handicap calculation
│   ├── LocationService.swift     # GPS rangefinder
│   ├── AICaddyService.swift      # AI-powered recommendations
│   ├── PremiumManager.swift      # RevenueCat IAP management
│   └── GameEngine.swift          # All game calculators (800+ lines)
├── ViewModels/                   # MVVM view models
│   ├── AuthViewModel.swift       # Auth state, profile management
│   ├── RoundViewModel.swift      # Live round, scoring, game sync
│   ├── AnalyticsViewModel.swift  # Stats, trends, export
│   ├── MoneyViewModel.swift      # Balances, settlements
│   └── GamesLibraryViewModel.swift
├── Views/
│   ├── Auth/LoginView.swift      # Sign in/up, Apple Sign-In
│   ├── Dashboard/DashboardView.swift
│   ├── Round/StartRoundView.swift # 4-step round setup wizard
│   ├── Scoring/LiveScorecardView.swift # Real-time scorecard + GPS
│   ├── Games/
│   │   ├── GamesLibraryView.swift     # Browse/create games
│   │   └── GameTrackerView.swift      # Live game status
│   ├── Money/PostRoundView.swift      # Settlement & payouts
│   ├── AICaddy/AICaddyView.swift      # Club/strategy AI
│   ├── Analytics/AnalyticsDashboardView.swift
│   ├── Profile/ProfileView.swift
│   └── Premium/PremiumView.swift
├── Extensions/
│   ├── Date+Extensions.swift
│   └── Color+Extensions.swift
├── Resources/
│   └── GoogleService-Info.plist.template
└── Assets.xcassets/
firebase/
├── firebase.json
├── firestore.rules              # Security rules
├── firestore.indexes.json       # Composite indexes
└── functions/
    ├── index.js                 # Cloud Functions (handicap, cleanup)
    └── package.json
```

## Features

### 1. Authentication & Profiles
- Email/password, Apple Sign-In, Google Sign-In
- User profiles with photo, home course, handicap
- Friends system with username search

### 2. Handicap Management (USGA/WHS)
- Best 8 of last 20 Score Differentials
- Exceptional score detection
- Automatic Course Handicap calculation
- Score Differential = (113 / Slope) × (Adjusted Gross – Course Rating)

### 3. Live Scoring
- Real-time scorecard synced via Firestore
- GPS rangefinder (distance to green in yards)
- Stroke play, Stableford, Match Play formats
- Track putts, fairways, GIR, sand shots per hole

### 4. Golf Games (14 Built-in Formats)

| Game | Players | Description |
|------|---------|-------------|
| **Nassau** | 2+ | Front 9, Back 9, Overall 18 with optional presses |
| **Skins** | 2+ | Per-hole winner with carryover on ties |
| **Wolf** | 4 | Rotating Wolf goes alone (1v3) or picks partner (2v2) |
| **Bingo Bango Bongo** | 2+ | Points for first on green, closest to pin, first in hole |
| **Dots / Garbage** | 2+ | Side bets: birdies, sand saves, greenies |
| **Las Vegas** | 4 | Team scores combined as 2-digit numbers |
| **Sixes / Round Robin** | 4 | Rotating partners every 6 holes |
| **Stableford** | 2+ | Points-based (0-5 per hole) |
| **Match Play** | 2 | Hole-by-hole wins |
| **Snake** | 2+ | Last to 3-putt holds the snake |
| **Banker** | 3+ | One player banks each hole |
| **9-Point / Niners** | 3 | 9 points split per hole (5-3-1) |
| **Best Ball** | 4 | Best team score per hole |
| **Custom** | Any | Build your own rules |

### 5. Money Management
- Virtual pot tracking with atomic Firestore transactions
- Running ledger: who owes whom
- Settlement screen with minimized transactions
- Export summary for manual payment (Venmo/PayPal/cash)
- **No real-money gambling** — entertainment tracking only

### 6. AI Caddy
- Club recommendation based on distance, lie, wind, elevation
- Shot strategy advice
- Post-round analysis with specific improvement tips
- Powered by Google Generative AI (Gemini)

### 7. Analytics & Insights
- Personal dashboard: scoring, putting, fairways, GIR trends
- SwiftUI Charts with trend visualization
- Head-to-head records and friend leaderboards
- CSV export of round history

## Monetization

| Feature | Free | Premium ($9.99/mo or $79.99/yr) |
|---------|------|----------------------------------|
| Basic scoring | ✅ | ✅ |
| Nassau & Skins | ✅ | ✅ |
| All 14 games | ❌ | ✅ |
| Custom Game Creator | ❌ | ✅ |
| AI Caddy | ❌ | ✅ |
| Advanced Analytics | ❌ | ✅ |
| Unlimited Groups | ❌ | ✅ |
| Ad-free | ❌ | ✅ |

## Setup

### Prerequisites
- Xcode 15+ with iOS 17 SDK
- Firebase project with Firestore, Auth, Functions enabled
- RevenueCat account for IAP
- Google AI API key for AI Caddy

### Steps

1. **Clone the repo**
   ```bash
   git clone https://github.com/elite2700/Elite360.whackfuck.git
   ```

2. **Open in Xcode**
   - Open `Package.swift` or the `.xcodeproj`
   - SPM will resolve Firebase, RevenueCat, and Google AI dependencies

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Download `GoogleService-Info.plist` and place in `Elite360Whackfuck/Resources/`
   - Enable Email/Password and Apple Sign-In in Firebase Auth
   - Create Firestore database

4. **Configure RevenueCat**
   - Replace `YOUR_REVENUECAT_API_KEY` in `PremiumManager.swift`

5. **Configure AI Caddy**
   - Replace `YOUR_API_KEY_HERE` in `AICaddyService.swift` with your Google AI key

6. **Deploy Cloud Functions**
   ```bash
   cd firebase && npm install && firebase deploy --only functions,firestore
   ```

7. **Build & Run** on iOS simulator or device

## Security & Legal

- **Firestore Security Rules** enforce per-user data access
- **No direct in-app payments** for gambling — all money tracking is for entertainment
- **Offline support** via Firestore persistence
- **Encrypted** money tracking data
- Legal disclaimer displayed throughout the app

## Future Roadmap

- Multi-round leagues & tournament modes
- Apple Watch companion app
- Arccos/Shot Scope integration for auto-shot tracking
- Apple Vision Pro course AR
- GHIN handicap import
- Social feed & activity sharing

---

**Elite360.Whackfuck** — *No-holds-barred golf fun, fully tracked.*
The Elite360.Whackfuck app (iOS-only, built with Swift/SwiftUI, integrated with Firebase for backend services) is designed as a premium, social golf companion app for serious golfers who want to elevate their rounds with competitive games, money management, analytics, and AI assistance. It targets groups of friends or leagues who play for stakes, while providing tools for personal improvement.
The name combines “Elite” for high-level play, “360” for comprehensive coverage (full game analytics, all angles), and “Whackfuck” as a fun, edgy twist on “whack” (hitting the ball) — perhaps implying intense, no-holds-barred golf fun.
Core Tech Stack
        •       Frontend: SwiftUI for modern, responsive iOS UI (iOS 17+ target).
        •       Backend: Firebase (Authentication, Firestore for data storage, Cloud Functions for complex calculations, Cloud Storage for user photos/stats exports, Firebase ML Kit or Cloud ML for basic AI features).
        •       Other: Core Location + MapKit for course GPS, RevenueCat or StoreKit for in-app purchases (premium features), optional Apple Pay integration for money transfers (note: direct wagering may require legal compliance; app focuses on tracking “fun money” or virtual pots, with manual settlement advised).
Key Features & Architecture
        1       User Authentication & Profiles
        ◦       Firebase Auth (email, Apple Sign-In, Google).
        ◦       Profile: Name, photo, home course, current Handicap Index (manual entry or import).
        ◦       Friends system: Add via username/search, create groups/foursomes.
        2       Handicap Management
        ◦       Users input scores post-round; app calculates Handicap Index using USGA/World Handicap System rules (best 8 of last 20 Score Differentials averaged, with safeguards for exceptional scores).
        ◦       Store scores in Firestore per user.
        ◦       Auto-pull or sync with official GHIN if API available (future integration); otherwise manual.
        ◦       Net scoring option for games (apply course handicap per hole).
        3       Scoring System
        ◦       Live scorecard with GPS rangefinder (distance to green, hazards).
        ◦       Real-time scoring synced via Firestore for group play (everyone sees updates).
        ◦       Supports stroke play, stableford, match play formats.
        ◦       Auto-calculate gross/net scores, putts, GIR, fairways hit (manual input or Apple Watch integration later).
        4       Golf Games & Side Bets
        ◦       Pre-built popular golf side games/betting formats (researched from common sources like Nassau, Skins, etc.):
        ▪       Nassau — Three separate bets: front 9, back 9, overall 18 (with optional presses).
        ▪       Skins — Per-hole winner takes the “skin” (carryover on ties); gross/net options.
        ▪       Wolf — Rotating “Wolf” decides to go alone or partner after drives (strategic 1v3 or 2v2).
        ▪       Bingo Bango Bongo — Points for first on green (Bingo), closest to pin once all on (Bango), first to hole out (Bongo).
        ▪       Dots / Garbage — Side bets for pars, birdies, sand saves, greenies, etc.
        ▪       Las Vegas / Vegas — Pair scores (e.g., 4&5 becomes 45 or 54 based on who wins hole).
        ▪       Sixes / Round Robin — Rotating partners every 6 holes.
        ▪       Stableford — Points-based scoring.
        ▪       Match Play — Hole-by-hole wins.
        ▪       Others: Snake (longest putt lost), Banker, 9-Point/Niners, Best Ball.
        ◦       Custom Game Creator — Users build their own: define points system, per-hole bets, presses, triggers (e.g., auto-press when down by X), team/individual, gross/net, min/max stakes.
        ◦       Stakes in virtual “pot” or tracked money (e.g., $ per point/hole); app calculates winnings/losses in real-time, shows running totals and final settlement screen.
        5       Money Handling
        ◦       Track virtual currency or “pot” per round/group (Firestore transactions for atomic updates).
        ◦       Running ledger: Who owes whom, total balances.
        ◦       Settlement: Export summary (e.g., “Player A owes Player B $45”) for manual Venmo/PayPal/cash.
        ◦       Caution: No direct in-app payments for real gambling to comply with laws; position as “friendly tracking tool.” Premium unlock for advanced money stats.
        6       AI Caddy
        ◦       Basic AI advisor using Firebase ML or integrated model (e.g., club recommendation based on distance, lie, wind — input manually).
        ◦       Shot suggestions: “With your 7-iron average, aim for the center of the green.”
        ◦       Post-round analysis: “You lost 3 strokes on approach shots — focus on 150-175 yard clubs.”
        ◦       Future: Integrate with Apple Vision or camera for lie detection (advanced).
        7       Golf Analytics & Insights
        ◦       Personal dashboard: Strokes gained (approach, putting, driving — approximate via user inputs), trends over time.
        ◦       Round history, stats graphs (fairways hit %, scrambling %, putts per round).
        ◦       Group comparisons: Leaderboards, head-to-head records.
        ◦       Export PDF/CSV summaries.
App Flow / Screens
        •       Home/Dashboard: Recent rounds, upcoming games, handicap overview, friends activity.
        •       Start Round: Select course (GPS/map), add players, choose/create game(s), set stakes.
        •       On-Course: Live scorecard, game trackers (e.g., skins carryover, wolf decisions), AI tips popup.
        •       Post-Round: Score review, analytics, settlement screen, save to history.
        •       Games Library: Browse pre-built, create custom, save favorites.
        •       Profile/Settings: Handicap edit, friends, premium subscription.
Monetization & Premium
        •       Free tier: Basic scoring, limited games (e.g., Nassau/Skins only), no custom creator.
        •       SuperGrok/Premium subscription (via IAP): Unlimited games, custom creator, advanced analytics, AI caddy, ad-free, unlimited groups.
Development Considerations
        •       Offline support: Cache rounds in Core Data, sync when online (Firebase offline persistence).
        •       Security: Private groups, encrypted money tracking.
        •       Legal: Disclaimer that app is for entertainment; no real-money gambling facilitation.
        •       Future expansions: Multi-round leagues, tournament modes, integration with Arccos/Shot Scope for auto-shot tracking.
This blueprint provides a solid foundation for Elite360.Whackfuck — a one-stop app that combines social competition, money stakes, and performance insights to make every round more engaging and data-driven
