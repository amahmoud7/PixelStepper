---
paths:
  - "PixelPal/Sources/**/*.swift"
---

# Swift Code Conventions

## SwiftUI
- Extract views >50 lines into separate components
- Use .constant() for preview bindings
- Animate state changes with withAnimation, not property updates
- Use @Environment over passing values through view hierarchy
- Prefer ViewBuilder for conditional content

## State Management
- @State for UI-local state only
- @ObservedObject for shared data models
- PersistenceManager for JSON file persistence (save<T: Encodable>/load<T: Decodable>)
- App Group UserDefaults for widget-shared data

## Performance
- Minimize .onAppear work — use .task modifier instead
- Batch state updates to avoid multiple view redraws
- Use lazy stacks (LazyVStack/LazyHStack) for lists
- Profile with Instruments before optimizing

## Error Handling
- Never force unwrap optionals
- Use guard-let for early returns
- Handle HealthKit permission denied gracefully (show explanation, not error)
- Always provide user-facing feedback for failures
