# Claude Agent Instructions — Pixel Pal (iOS)

You are an expert iOS engineer. Your job is to help build Pixel Pal v1 with ruthless scope control and correct iOS architecture.

## Product Goal (v1)
Build an iOS app that:
1) Reads today's step count from HealthKit (user permission required)
2) Maps steps -> 3 energy states: vital, neutral, low
3) Shows a pixel character (two gender variants) that:
   - Appears in a Live Activity (Lock Screen + Dynamic Island)
   - "Animates" by toggling 2 frames using local SwiftUI timing (TimelineView periodic)
4) Optionally shows a Home Screen widget that displays the current state (static snapshot, no expectation of continuous animation)

## Non-negotiable constraints
- Do NOT attempt real-time widget animation via WidgetKit. Widgets refresh infrequently and are OS-throttled.
- The 2-frame toggle animation must be achieved via local SwiftUI rendering in the Live Activity view (TimelineView .periodic).
- Do NOT update Live Activity content every second. Update only when step count/state meaningfully changes (e.g., app foreground fetch, periodic background best-effort).
- No shame language. The low state is "tired/low energy", not moral failure.
- v1: no customization beyond gender selection. No XP/coins/levels/streaks.

## Required outputs from you
- A working Xcode project structure: App target + Widget Extension (WidgetKit + ActivityKit)
- Correct entitlements and capabilities:
  - HealthKit
  - App Groups
  - Live Activities
- Clean code with small files, clear responsibilities
- A minimal UI in-app:
  - Onboarding: gender selection
  - Button: "Enable Live Activity"
  - Display: current steps + current state

## Asset conventions (must match)
Sprites (32x32 PNG, transparent) in Asset Catalog with these names:
male_vital_1, male_vital_2
male_neutral_1, male_neutral_2
male_low_1, male_low_2
female_vital_1, female_vital_2
female_neutral_1, female_neutral_2
female_low_1, female_low_2

All sprites share the same base skeleton/proportions; gender differs only by hair/clothing silhouette.

## Data model
- Gender: male | female (stored in App Group UserDefaults)
- Steps: Int (today)
- State: vital | neutral | low
- UpdatedAt: Date

## State mapping (v1 simple thresholds)
0..1999 -> low
2000..7499 -> neutral
7500+ -> vital

## Implementation details
- HealthKit:
  - Request read access to stepCount
  - Use HKStatisticsQuery cumulativeSum from startOfDay to now
- App Groups:
  - Store current snapshot to shared UserDefaults suite
- Live Activity:
  - PixelPalAttributes with ContentState: steps, stateRaw, genderRaw
  - UI uses TimelineView(.periodic) to toggle frames every ~0.6–1.0 seconds
  - Use interpolation(.none) to preserve pixel crispness

## Code quality requirements
- No giant God files
- No "magic strings" for asset names; centralize naming helpers
- Defensive handling when HealthKit not available or permission denied
- Ensure review-friendly: the reviewer can open app, grant permission, start Live Activity, see it update

## What to avoid
- Any background hacks to keep Live Activity alive forever
- Any per-second network updates or push updates
- Any analytics dashboard or feature creep

When uncertain, pick the simplest, most reviewer-proof approach.

## Build & Development Commands

```bash
# Regenerate Xcode project (REQUIRED after adding/removing files)
xcodegen generate

# Build (no code signing for CI/automation)
xcodebuild -project PixelPal.xcodeproj -scheme PixelPal -destination 'generic/platform=iOS' build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run tests
xcodebuild test -project PixelPal.xcodeproj -scheme PixelPal -destination 'platform=iOS Simulator,name=iPhone 16'
```

## File Organization
- **App sources:** `PixelPal/Sources/` (recursive — XcodeGen auto-includes)
- **Widget sources:** Explicit paths in `project.yml` (NOT recursive)
- **Shared files:** `AvatarState.swift`, `SharedData.swift`, `SpriteAssets.swift`, `PixelPalAttributes.swift`
- **Project config:** `project.yml` (XcodeGen spec)
- **Agents:** `agents/` (specialized analysis agents with coordinator)

When adding new files: create on disk in `PixelPal/Sources/`, then run `xcodegen generate` to sync the Xcode project.
