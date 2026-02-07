---
paths:
  - "PixelPalTests/**/*.swift"
  - "**/*Tests.swift"
  - "**/*Test.swift"
---

# Testing Guidelines

## Test Structure
- One test file per source file (e.g., AvatarStateTests.swift for AvatarState.swift)
- Use descriptive test names: test_functionName_condition_expectedResult
- Arrange-Act-Assert pattern

## What to Test
- State transitions: low → neutral → vital thresholds (0-2499, 2500-7499, 7500+)
- Phase thresholds: 25k, 75k, 200k cumulative steps
- PersistenceManager save/load round-trips
- Edge cases: 0 steps, negative steps, Int.max
- HealthKit permission states (authorized, denied, notDetermined)

## What NOT to Test
- SwiftUI view layout (use Xcode previews instead)
- Apple framework internals (HealthKit query execution, WidgetKit timeline scheduling)
- Private methods — test through public API

## Running Tests
```bash
xcodebuild test -project PixelPal.xcodeproj -scheme PixelPal -destination 'platform=iOS Simulator,name=iPhone 16'
```
