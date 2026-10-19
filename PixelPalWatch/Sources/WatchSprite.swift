import SwiftUI

/// The pixel character: a 2-frame idle toggle every 0.8s (same cadence as the Live Activity).
struct WatchSprite: View {
    let gender: Gender
    let state: AvatarState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            sprite(frame: 1)
        } else {
            TimelineView(.periodic(from: .now, by: 0.8)) { context in
                sprite(frame: Int(context.date.timeIntervalSinceReferenceDate / 0.8) % 2 + 1)
            }
        }
    }

    private func sprite(frame: Int) -> some View {
        Image(decorative: SpriteAssets.spriteName(gender: gender, state: state, frame: frame))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}
