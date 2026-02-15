# Pixel Stepper - App Store Metadata

## App Information

**App Name:** Pixel Stepper

**Subtitle:** Walk, evolve & grow your companion

**Category:** Health & Fitness

**Bundle ID:** com.pixelpalfit.app

---

## Description

Meet your walking companion that lives on your Lock Screen.

Pixel Stepper turns your daily steps into a living pixel character. No guilt trips. No overwhelming dashboards. Just a tiny friend whose energy reflects how much you move.

**How it works:**
- Your character appears on your Lock Screen and Dynamic Island
- Walk more, and they become more energetic
- Complete daily missions to earn Step Coins
- Track your streak and build consistency
- Keep walking to unlock new evolution phases

**Features:**
- Live Activity on Lock Screen & Dynamic Island
- Adorable 2-frame pixel animation
- 4 evolution phases to unlock through walking
- 3 daily missions that refresh every day
- Weekly challenges for extra rewards
- Step Coins earned through real movement
- Streak tracking with daily step goals
- 30-day activity calendar and personal records
- Share cards to show off your progress
- Home Screen widgets (small, medium, large)
- No ads, no spam notifications

**Coming soon:** Wardrobe & Cosmetic Shop — spend your Step Coins on hats, backgrounds, and accessories to style your companion.

Pixel Stepper isn't another step counter. It's a quiet companion that walks with you.

---

## Keywords

pixel,walking,steps,pedometer,companion,tamagotchi,pet,widget,lock screen,dynamic island,fitness,streak,missions,motivation,avatar

---

## What's New (Version 2.1.0)

Massive update! Here's what's new:

- Daily missions — complete 3 quests every day to earn Step Coins
- Weekly challenges for bonus rewards
- Streak tracking — build your daily walking streak
- 30-day activity calendar and personal records
- Step count front and center on the Home tab
- Share cards to show off your progress
- Improved widget with real-time step data
- Phase progress tracking in Stats
- Better HealthKit sync on app resume
- Wardrobe & Cosmetic Shop coming soon!

---

## Promotional Text

Your daily steps bring a pixel companion to life — right on your Lock Screen. Complete missions, build streaks, and earn Step Coins!

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
For questions, contact akrammahmoud@example.com

---

## Support URL Text

https://github.com/amahmoud7/PixelStepper/issues

---

## In-App Purchase Descriptions

### Monthly Premium ($2.99/month)
**Display Name:** Monthly Premium
**Description:** Unlock all evolution phases, 2x Step Coins, exclusive cosmetics, weekly challenges, streak freeze, and premium share cards. Cancel anytime.

### Yearly Premium ($19.99/year)
**Display Name:** Yearly Premium
**Description:** Best value! Everything in Monthly Premium at over 35% savings. Unlock all phases, 2x coins, exclusive cosmetics, and more.

---

## App Review Notes

**HealthKit Usage:**
Pixel Stepper reads step count data from HealthKit to determine the character's energy state (vital/neutral/low), track daily missions, calculate streaks, and award Step Coins. This is the core mechanic of the app - the character's appearance and progression reflect the user's daily movement. The HealthKit permission request uses the standard system dialog with neutral button text ("Continue"). If the user declines permission, the app remains fully functional but step data shows as 0, and a help banner provides guidance on enabling access through the Health app.

**Live Activity:**
The app uses Live Activities to display the pixel character on the Lock Screen and Dynamic Island. The character animates between 2 frames locally using TimelineView. Live Activity content updates when step count changes significantly (not continuously).

**Step Coins:**
Step Coins are a virtual currency earned exclusively through walking activity (completing daily missions, maintaining streaks, hitting step milestones). No real money can purchase Step Coins directly — they are purely earned through physical activity. A Cosmetic Shop where coins can be spent on avatar customization is planned for a future update and currently shows a "Coming Soon" prompt.

**Business Model:**
1. **Who are the users?** Health-conscious individuals who want a fun, gamified walking motivation app. The app is suitable for all ages (4+).
2. **Where can users purchase features?** Premium subscriptions are available exclusively through Apple's in-app purchase system (StoreKit 2). The paywall is accessible from the Home tab (crown icon) and the Profile tab. Subscriptions are auto-renewable.
3. **What can premium users access?** Premium subscribers unlock: all 4 evolution phases (free users get phases 1-2), 2x Step Coin earnings, weekly challenges, streak freeze protection, and premium share card styles.
4. **What is available without purchase?** The core app is fully functional for free: step tracking, pixel character animation, Live Activity, Home Screen widget, phases 1-2, 3 daily missions, streak tracking, and standard share cards. Premium enhances the experience but is not required.

**Demo Instructions:**
1. Launch app and complete onboarding (select gender, tap "Continue")
2. The system HealthKit permission dialog will appear — grant or deny (app works either way)
3. The home screen shows your pixel avatar with current step count
4. Swipe between Home, Stats, and Profile tabs
5. Home tab: View avatar, streak info, daily missions
6. Stats tab: View weekly history, personal records, phase progress
7. Profile tab: Personal stats, Live Activity toggle, premium card
8. Profile tab → Wardrobe shows "Coming Soon" alert (Cosmetic Shop in development)
9. To test Premium: Profile tab → tap "Unlock Premium" or Home tab → crown icon
10. Walk to see character energy change and missions progress

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
5. "Evolve through 4 phases"

---

## Checklist Before Submission

- [ ] Save app icon (1024x1024) to AppIcon.appiconset/AppIcon.png
- [ ] Take screenshots on iPhone 16 Pro (6.9")
- [ ] Take screenshots on iPhone 8 Plus (5.5")
- [ ] Update App Store Connect app listing with new description
- [ ] Verify in-app purchases match pricing ($2.99/$19.99)
- [ ] Upload privacy policy to web URL
- [ ] Test on physical device
- [ ] Verify HealthKit permission flow works correctly
- [ ] Verify Wardrobe shows "Coming Soon" alert
- [ ] Archive and upload build
- [ ] Submit for review
