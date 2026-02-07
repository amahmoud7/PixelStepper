---
paths:
  - "PixelPalWidget/**/*.swift"
---

# Widget Extension Rules

## Live Activity Animation
- MUST use TimelineView(.periodic) for frame toggling — NOT Timer-based updates
- Apple rate-limits widget content updates — periodic views are the only safe pattern
- Toggle animation frames every ~0.6-1.0 seconds
- Use interpolation(.none) to preserve pixel art crispness

## Memory & Performance
- Widget memory limit: 30MB — keep views lightweight
- Minimize image decoding — use pre-rendered assets from Asset Catalog
- No network calls in widget views
- No heavy computation in widget timeline providers

## Shared Files
- AvatarState.swift, SharedData.swift, SpriteAssets.swift, PixelPalAttributes.swift
- These are explicitly listed in project.yml — adding new shared files requires updating project.yml AND running xcodegen generate

## Content State
- PixelPalAttributes with ContentState: steps (Int), stateRaw (String), genderRaw (String)
- Keep ContentState minimal — only what the widget needs to render
