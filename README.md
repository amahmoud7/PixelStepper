# Pixel Pace

Your steps tell a story. Pixel Pace transforms your daily movement into an evolving pixel companion that lives on your Lock Screen, Dynamic Island, and Home Screen.

Not another step counter. An ambient identity system that reinforces movement through visual pride — not guilt, streaks, or notifications.

## How It Works

Walk more, and your character evolves. Four phases of permanent progression based on your weekly steps:

| Phase | Weekly Steps | Character |
|-------|-------------|-----------|
| Dormant | 0–25k | Low energy, resting posture |
| Active | 25k–50k | Steady, alert movement |
| Energized | 50k–75k | Dynamic animations, glow effects |
| Ascended | 75k+ | Rare form, full radiance |

Evolution is permanent — once you reach a phase, you never lose it.

## Features

- **Live Activity** — Your character animates on the Lock Screen and Dynamic Island using efficient local rendering
- **Home Screen Widget** — Static snapshot of your current state and phase
- **4-Phase Evolution** — Permanent character progression tied to weekly movement
- **32-Frame Walking Animation** — Smooth pixel art at 24fps when you're active
- **7-Day Memory** — Visual history of your daily goals
- **Premium Tiers** — Unlock Phases 3–4, exclusive skins, and full history ($2.99/mo or $19.99/yr)
- **Zero Guilt Design** — Low energy state is "tired," never shaming. No streaks, no punishment.

## Screenshots

Interactive mockups available in `demo/`:

```bash
python3 -m http.server 8000
# Open http://localhost:8000/demo/iphone-simulator.html
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | SwiftUI |
| Lock Screen & Dynamic Island | ActivityKit + Live Activities |
| Home Screen Widget | WidgetKit |
| Step Data | HealthKit (read-only) |
| Subscriptions | StoreKit 2 |
| Data Persistence | JSON files via PersistenceManager |
| Widget Communication | App Groups |
| Project Generation | XcodeGen |

**Requirements:** iOS 16.2+ (optimal on iOS 17.0+), Xcode 15.0+, Swift 5.9

## Build

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build (no code signing)
xcodebuild -project PixelPal.xcodeproj -scheme PixelPal \
  -destination 'generic/platform=iOS' build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run tests
xcodebuild test -project PixelPal.xcodeproj -scheme PixelPal \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

```
HealthKit → HealthKitManager → ProgressState → LiveActivityManager
                 │                                    │
           ContentView (app)              PixelPalLiveActivity (widget)
                 │
          SharedData (App Group)
                 │
         PixelPalWidget (Home Screen)
```

**Key Managers:**
- `HealthKitManager` — Step queries with 1-hour cache
- `LiveActivityManager` — Live Activity lifecycle and animation timing
- `PersistenceManager` — Generic JSON persistence with Codable
- `StoreManager` — StoreKit 2 product loading and entitlements
- `PhaseCalculator` — Phase computation from weekly steps
- `HistoryManager` — 30-day rolling daily goal tracking

## Project Structure

```
PixelPal/Sources/
├── App/                    # Entry point
├── Core/                   # HealthKit, Live Activity, shared data
│   ├── Managers/           # Persistence, history, subscriptions
│   └── Models/             # UserProfile, ProgressState, entitlements
└── Views/                  # SwiftUI screens

PixelPalWidget/Sources/     # Widget extension (Live Activity + Home Screen)
PixelPalTests/              # Unit tests
demo/                       # Interactive HTML mockups
agents/                     # AI agent definitions for code analysis
```

## Sprite System

81 imagesets — 32x32 pixel art, transparent PNG, no anti-aliasing:

- **State sprites** (12): `{gender}_{state}_{frame}` — idle animations
- **Walking sprites** (64): `{gender}_walking_{frame}` — 32-frame walk cycle
- Two gender variants with shared skeleton, differing by hair/clothing silhouette

## Privacy

Pixel Pace reads step count data from HealthKit. No data leaves your device. No analytics, no tracking, no accounts. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## License

All rights reserved.
