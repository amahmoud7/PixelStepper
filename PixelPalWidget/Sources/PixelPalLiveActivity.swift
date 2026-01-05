import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity configuration for Pixel Pal.
/// Displays an animated sprite on Lock Screen and Dynamic Island.
struct PixelPalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PixelPalAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact Leading: Mini sprite
                CompactLeadingView(context: context)
            } compactTrailing: {
                // Compact Trailing: Step count
                CompactTrailingView(context: context)
            } minimal: {
                // Minimal: Tiny sprite only
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            genderRaw: context.state.genderRaw,
            stateRaw: context.state.stateRaw,
            frame: 1
        )

        HStack(spacing: 16) {
            if let uiImage = UIImage(named: spriteName) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.steps) steps")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(context.state.stateRaw.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding()
        .activityBackgroundTint(.black)
    }
}

// MARK: - Dynamic Island Expanded Views

private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            genderRaw: context.state.genderRaw,
            stateRaw: context.state.stateRaw,
            frame: 1
        )

        if let uiImage = UIImage(named: spriteName) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
    }
}

private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(context.state.steps)")
                .font(.title2)
                .fontWeight(.bold)
            Text("steps")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct ExpandedCenterView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        Text(context.state.stateRaw.capitalized)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

private struct ExpandedBottomView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        Text("Updates periodically")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}

// MARK: - Dynamic Island Compact Views

private struct CompactLeadingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            genderRaw: context.state.genderRaw,
            stateRaw: context.state.stateRaw,
            frame: 1
        )

        if let uiImage = UIImage(named: spriteName) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        Text("\(context.state.steps)")
            .font(.caption)
            .fontWeight(.semibold)
    }
}

// MARK: - Dynamic Island Minimal View

private struct MinimalView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            genderRaw: context.state.genderRaw,
            stateRaw: context.state.stateRaw,
            frame: 1
        )

        if let uiImage = UIImage(named: spriteName) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}
