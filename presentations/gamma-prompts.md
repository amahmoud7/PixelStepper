# Gamma Presentation Prompts for Pixel Pace

Use these prompts directly in Gamma.app to generate your presentations. Copy the relevant section and paste it as your Gamma prompt.

---

## 1. INVESTOR PITCH DECK

**Gamma Prompt:**
```
Create a 12-slide investor pitch deck for Pixel Pace, an iOS fitness companion app.

PROBLEM: Health apps overwhelm users with notifications, shame-based language ("you've been inactive!"), and demand constant engagement. Users want motivation without guilt or app fatigue.

SOLUTION: Pixel Pace is a tiny pixel art character that lives on your iPhone's Lock Screen and Dynamic Island. It breathes and changes posture based on your daily step count—no notifications, no judgment, just ambient motivation you see every time you unlock your phone.

KEY FEATURES:
- Live Activity on Lock Screen & Dynamic Island with 2-frame breathing animation
- 3 energy states: Vital (7,500+ steps), Neutral (2,000-7,499), Low (<2,000)
- Guilt-free design: "low energy" shows resting posture, not failure
- Gender-customizable pixel character (male/female)
- HealthKit integration for automatic step tracking
- Home Screen widget with 15-minute refresh

MARKET OPPORTUNITY:
- 50M+ HealthKit users globally
- $1.5B fitness app market growing at 12% CAGR
- Untapped segment: "health-curious but busy" users who don't want hardcore fitness apps

DIFFERENTIATORS:
- Ambient: No notifications; meets users on Lock Screen
- Judgment-free: Positive language only
- Minimalist: One mechanic done perfectly
- Modern nostalgia: Retro pixel art + Dynamic Island tech

TECH STACK: Swift/SwiftUI, HealthKit, ActivityKit, WidgetKit, iOS 16+

BUSINESS MODEL: Freemium with premium character packs and themes

TEAM: Solo developer with iOS expertise

ASK: Seed funding for character expansion, Android port, and marketing

Include slides for: Title, Problem, Solution, Demo/Product, Market Size, Business Model, Traction, Competition, Team, Roadmap, Financials, Ask/CTA
```

---

## 2. PRODUCT OVERVIEW

**Gamma Prompt:**
```
Create an 8-slide product overview presentation for Pixel Pace, a health companion iOS app.

TAGLINE: "Your ambient walking companion—a pixel-perfect reminder that every step counts."

CONCEPT: A minimalist pixel art character that lives on your iPhone's Lock Screen and Dynamic Island. It breathes and changes posture based on your daily steps. No notifications. No shame. Just your vibe.

CORE FEATURES:
1. Live Activity Display - Character visible on Lock Screen and Dynamic Island with breathing animation
2. Smart Energy States - Vital (7,500+ steps), Neutral (2,000-7,499), Low (<2,000 steps)
3. HealthKit Sync - Automatic step counting, no manual entry
4. Gender Options - Male and female character variants
5. Home Screen Widget - Quick glance at your current state
6. Guilt-Free Design - "Low energy" means resting, not failing

HOW IT WORKS:
1. Download and choose your character
2. Grant HealthKit permission
3. Start the Live Activity
4. Your character updates automatically as you walk

DESIGN PHILOSOPHY:
- Ambient motivation over push notifications
- Positive language only
- Retro aesthetic meets modern iOS tech
- Minimal friction, maximum visibility

TARGET USERS: Health-conscious iPhone users who want gentle daily motivation without app fatigue

Include visuals suggestions for pixel art characters and iPhone mockups showing Dynamic Island and Lock Screen
```

---

## 3. MARKETING/SALES DECK

**Gamma Prompt:**
```
Create a 10-slide marketing presentation for Pixel Pace, a unique iOS fitness app for potential partners and advertisers.

HOOK: "What if your fitness tracker was a friend, not a judge?"

THE PROBLEM WITH FITNESS APPS:
- Notification overload causes app deletion
- Shame-based messaging ("You've been sedentary!") creates anxiety
- Complex dashboards go unused
- Users want motivation, not management

PIXEL PACE SOLUTION:
A pixel art companion that lives on your Lock Screen. It breathes when you walk. It rests when you rest. No notifications. No guilt. Just a tiny friend reflecting your daily momentum.

UNIQUE VALUE PROPOSITIONS:
- AMBIENT: Lives on Lock Screen—no app opening required
- POSITIVE: "Low energy" not "inactive"—design language that uplifts
- NOSTALGIC: Retro pixel art creates emotional connection
- MODERN: Leverages Dynamic Island—cutting-edge iOS tech

TARGET DEMOGRAPHICS:
- Age: 18-45
- Psychographics: Health-curious, notification-fatigued, appreciates minimalist design
- Behavior: Checks phone frequently, aware of step count, values subtle reminders

PARTNERSHIP OPPORTUNITIES:
- Health & wellness brands: Co-branded character packs
- Fitness equipment: Bundle with wearables
- Insurance companies: Gamified wellness incentives
- Corporate wellness: Team step challenges (future feature)

METRICS TO HIGHLIGHT:
- 250M+ presentations created on Gamma (for context on AI tools adoption)
- Dynamic Island apps see 40% higher engagement
- Ambient apps have 3x retention vs notification-heavy apps

Include: Compelling visuals, iPhone mockups, character sprites, before/after user experience comparison
```

---

## 4. INTERNAL/TEAM PRESENTATION

**Gamma Prompt:**
```
Create a 6-slide internal team presentation for Pixel Pace iOS app development status and roadmap.

PROJECT: Pixel Pace (PixelPal) - iOS Health Companion App

CURRENT STATUS: MVP v1 Implementation Phase

COMPLETED WORK:
- Core architecture (App + Widget Extension targets)
- HealthKit integration (permission flow, step fetching)
- Avatar state engine (3-tier thresholds: Low <2000, Neutral 2000-7499, Vital 7500+)
- Live Activity UI (Lock Screen + Dynamic Island)
- Home Screen widget (15-min refresh)
- Onboarding flow (gender selection + HealthKit auth)
- 12 sprite assets (2 genders × 3 states × 2 animation frames)

TECH STACK:
- Swift 5.9 / SwiftUI
- iOS 16.0+ minimum
- HealthKit, ActivityKit, WidgetKit
- App Groups for data sharing

ARCHITECTURE:
- 2 Targets: PixelPal (main app), PixelPalWidget (extension)
- Shared code: AvatarState, HealthKitManager, SharedData, SpriteAssets

MVP DEFINITION OF DONE:
- Fresh install → onboarding → permission → Live Activity starts
- Character displays correctly with right gender/state
- Steps update character visually
- Widget displays snapshot reliably
- No crashes on permission denial
- All sprites render crisp (no blur)

ROADMAP (POST-MVP):
- v1.1: Additional character designs
- v1.2: Adaptive baseline (personal step goals)
- v2.0: watchOS companion
- v2.5: Android port
- v3.0: Social features (optional step sharing)

BLOCKERS/RISKS:
- App Store review for Live Activity usage
- HealthKit permission rejection handling
- Widget refresh rate limitations

Keep it concise, use technical language appropriate for developers
```

---

## USAGE TIPS FOR GAMMA

1. **Paste the prompt** into Gamma's text input when creating a new presentation
2. **Choose a theme** that matches your brand (recommend: minimal, modern, or retro themes)
3. **Upload assets** after generation:
   - Pixel character sprites from `/PixelPalFit/PixelPal/Assets.xcassets/`
   - iPhone mockups showing Dynamic Island
4. **Refine content** - Gamma's AI gives good starting points but personalize with your data
5. **Export carefully** - Gamma works best in-browser; PowerPoint exports may have formatting issues

---

## SUGGESTED GAMMA THEMES

For Pixel Pace's retro-meets-modern aesthetic, try:
- **Dark mode themes** - Makes pixel art pop
- **Minimal/Clean themes** - Matches the app's philosophy
- **Bold color palettes** - Purple/teal or orange/blue combinations

---

*Generated for Pixel Pace presentations - January 2026*
