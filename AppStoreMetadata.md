# Pixel Stepper - App Store Metadata

## App Information

**App Name:** Pixel Stepper

**Subtitle:** Walk to evolve your tiny pet

**Category:** Health & Fitness

**Bundle ID:** com.pixelpalfit.app

---

## Description

Meet your walking companion that lives on your Lock Screen.

Pixel Stepper turns your daily steps into a living pixel character. No guilt trips. No overwhelming dashboards. Just a tiny friend whose energy reflects how much you move.

**How it works:**
- Your character appears on your Lock Screen and Dynamic Island
- Walk more, and they become more energetic
- Complete daily missions
- Track your streak and build consistency
- Keep walking to unlock new evolution phases

**Features:**
- Live Activity on Lock Screen & Dynamic Island
- Adorable 2-frame pixel animation
- 4 evolution phases to unlock through walking
- 3 daily missions that refresh every day
- Weekly challenges for extra rewards
- Streak tracking with daily step goals
- 30-day activity calendar and personal records
- Share cards to show off your progress
- Home Screen widgets (small, medium, large)
- No ads, no spam notifications

Pixel Stepper isn't another step counter. It's a quiet companion that walks with you.

---

## Keywords

walking,pedometer,step counter,pet,widget,lock screen,dynamic island,streak,missions,motivation

(95/100 chars. Words already in the name/subtitle and the category name are indexed automatically, so they're omitted.)

---

## What's New (Version 2.1.0)

Massive update! Here's what's new:

- Daily missions — 3 fresh goals every day
- Weekly challenges for bonus rewards
- Streak tracking — build your daily walking streak
- 30-day activity calendar and personal records
- Step count front and center on the Home tab
- Share cards to show off your progress
- Improved widget with real-time step data
- Phase progress tracking in Stats
- Better HealthKit sync on app resume

(Not shown for a first release; use from the first update onward.)

---

## Promotional Text

Your daily steps bring a pixel companion to life — right on your Lock Screen. Complete daily missions and build your streak.

---

## Privacy Policy Text

**Privacy Policy for Pixel Stepper**

Last updated: February 2026

Pixel Stepper ("we", "our", or "the app") respects your privacy. This policy explains how we handle your data.

**Data We Access:**
- Step count from Apple HealthKit (read-only)

**Data We Store:**
- Your character gender preference (on-device only)
- Your evolution progress, streak data, and coin balance (on-device only)
- Your cosmetic inventory and equipped items (on-device only)

**Data We DO NOT Collect:**
- Personal information
- Location data
- Usage analytics
- Advertising identifiers

**Third Parties:**
We do not share any data with third parties.

**HealthKit:**
Pixel Stepper accesses your step count solely to determine your character's energy state and track walking progress. This data is never transmitted off your device.

**Subscriptions:**
Premium features are managed through Apple's App Store. We do not process payments directly.

**Contact:**
For questions, open an issue at https://github.com/amahmoud7/PixelStepper/issues

---

## Privacy Policy URL

https://github.com/amahmoud7/PixelStepper/blob/main/PRIVACY_POLICY.md

## Terms of Use (EULA) URL

https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ (Apple standard EULA; also link it in the App Description or the EULA field in App Store Connect)

---

## Support URL Text

https://github.com/amahmoud7/PixelStepper/issues

---

## In-App Purchase Descriptions

### Monthly Premium ($2.99/month)
**Display Name:** Monthly Premium
**Description:** All 4 phases, 5 daily missions & streak freeze

### Yearly Premium ($19.99/year)
**Display Name:** Yearly Premium
**Description:** Best value: all premium features, billed yearly

---

## App Review Notes

**HealthKit Usage:**
Pixel Stepper reads step count data from HealthKit to determine the character's energy state (vital/neutral/low), track daily missions, and calculate streaks. This is the core mechanic of the app - the character's appearance and progression reflect the user's daily movement. The HealthKit permission request uses the standard system dialog with neutral button text ("Continue"). If the user declines permission, the app remains fully functional but step data shows as 0, and a help banner provides guidance on enabling access through the Health app.

**Live Activity:**
The app uses Live Activities to display the pixel character on the Lock Screen and Dynamic Island. The character animates between 2 frames locally using TimelineView. Live Activity content updates when step count changes significantly (not continuously).

**Business Model:**
1. **Who are the users?** Health-conscious individuals who want a fun, gamified walking motivation app. The app is suitable for all ages (4+).
2. **Where can users purchase features?** Premium subscriptions are available exclusively through Apple's in-app purchase system (StoreKit 2). The paywall is accessible from the Home tab (crown icon) and the Profile tab. Subscriptions are auto-renewable.
3. **What can premium users access?** Premium subscribers unlock: all 4 evolution phases (free users get phases 1-2), 5 daily missions, weekly challenges, streak freeze protection, and premium share card styles.
4. **What is available without purchase?** The core app is fully functional for free: step tracking, pixel character animation, Live Activity, Home Screen widget, phases 1-2, 3 daily missions, streak tracking, and standard share cards. Premium enhances the experience but is not required.

**Demo Instructions:**
1. Launch app and complete onboarding (select gender, tap "Continue")
2. The system HealthKit permission dialog will appear — grant or deny (app works either way)
3. The home screen shows your pixel avatar with current step count
4. Swipe between Home, Stats, and Profile tabs
5. Home tab: View avatar, streak info, daily missions
6. Stats tab: View weekly history, personal records, phase progress
7. Profile tab: Personal stats, Live Activity toggle, premium card
8. To test Premium: Profile tab → tap "Unlock Premium" or Home tab → crown icon
9. Walk to see character energy change and missions progress

---

## Age Rating

**Age Rating:** 4+

No objectionable content.

---

## Screenshot Captions

1. "Meet your walking companion"
2. "Lives on your Lock Screen"
3. "Complete daily missions"
4. "Track your streak & stats"
5. "Evolve through 4 phases" (paywall: phase auras, no prices)
6. "Choose your pixel companion" (onboarding)

---

## Checklist Before Submission

- [x] Save app icon (1024x1024, no alpha) to AppIcon.appiconset/AppIcon.png
- [ ] Screenshots: one set at 1206×2622 (iPhone 16 Pro / 17 Pro, 6.3"). Smaller sizes auto-scale; iPad not needed (iPhone-only). Lock Screen / Dynamic Island shot in the first 3. Flatten PNGs (no alpha).
- [ ] Optional app preview: 886×1920, 15–30 s, H.264, ≤30 fps, hook in first 3 s
- [ ] Update App Store Connect app listing with new description
- [ ] Verify in-app purchases match pricing ($2.99/$19.99) and IAP descriptions ≤55 chars
- [ ] Set Privacy Policy URL + privacy label "Data Not Collected"
- [ ] Pricing & Availability: uncheck Apple silicon Mac and Apple Vision Pro
- [ ] Run `xcodegen generate`, then tests, on the Mac
- [ ] Test on physical device
- [ ] Verify HealthKit permission flow works correctly
- [ ] Archive with the latest Xcode (iOS 27 SDK required from April 2027) and upload
- [ ] Submit for review
