# Pixel Pace — Roadmap

## v1.1 — Premium Widget Customization

### Feature: Widget Theme Selector (Premium)
Allow paid subscribers to choose from different visual themes for their Home Screen widgets (small, medium, large). Free users get the default theme. Theme selection is stored in App Group UserDefaults so the widget extension can read it.

**3 Theme Options:**

1. **Dark Cosmos** (Default / Free)
   - Deep purple-to-dark gradient background
   - Standard accent colors: green (vital), blue (neutral), orange (low)
   - White text, gray secondary text
   - Current look — ships as the free baseline

2. **Neon Pulse** (Premium)
   - Pure black background with vibrant neon accent glow
   - Cyan/magenta/electric-green state colors with soft glow halos
   - Step count rendered with neon gradient fill
   - Bar chart bars use neon accent with subtle bloom effect
   - Phase badge uses glowing border instead of filled background

3. **Nature Calm** (Premium)
   - Warm earth-tone gradient (deep forest green to dark brown)
   - Muted sage green (vital), warm sand (neutral), terracotta (low)
   - Cream/warm white text, soft shadows
   - Bar chart uses rounded organic shapes with earthy fills
   - Phase badge uses leaf-green tint

### Implementation Notes
- Add `WidgetTheme` enum: `.darkCosmos`, `.neonPulse`, `.naturCalm`
- Store selection in `SharedData` via App Group UserDefaults key `"widgetTheme"`
- Create `WidgetThemeProvider` that returns colors/gradients for each theme
- Gate theme 2 & 3 behind `StoreManager.isPremium` check
- Widget views read theme from SharedData and apply colors accordingly
- Add theme picker UI in ContentView (only for premium users, show locked state for free)
- Call `WidgetCenter.shared.reloadAllTimelines()` on theme change

### Future Considerations (v1.2+)
- Additional theme packs (seasonal, event-based)
- Custom color picker for premium+ tier
- Widget layout variants (stats-focused vs character-focused vs minimal)
