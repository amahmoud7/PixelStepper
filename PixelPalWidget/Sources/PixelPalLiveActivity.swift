import ActivityKit
import SwiftUI
import WidgetKit

struct PixelPalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PixelStepperAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
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
                CompactLeadingView(context: context)
            } compactTrailing: {
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Animated Sprite View (2-frame toggle via TimelineView)

private struct AnimatedSpriteView: View {
    let genderRaw: String
    let stateRaw: String
    let isWalking: Bool
    var size: CGFloat = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let frameInterval: TimeInterval = 0.8

    var body: some View {
        Group {
            if reduceMotion {
                sprite(frame: 1)
            } else {
                TimelineView(.periodic(from: .now, by: Self.frameInterval)) { timeline in
                    sprite(frame: Int(timeline.date.timeIntervalSince1970 / Self.frameInterval) % 2 + 1)
                }
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func sprite(frame: Int) -> some View {
        if let uiImage = UIImage(named: spriteName(frame: frame)) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Frame 1 or 2. Walking maps these to two key poses of the walk cycle.
    private func spriteName(frame: Int) -> String {
        if isWalking {
            let walkFrame = frame == 1 ? 1 : SpriteAssets.walkingFrameCount / 2 + 1
            return SpriteAssets.walkingSpriteName(genderRaw: genderRaw, frame: walkFrame)
        }
        return SpriteAssets.spriteName(genderRaw: genderRaw, stateRaw: stateRaw, frame: frame)
    }
}

// MARK: - Color Helpers

/// Mirrors the app's Theme RGB values (the widget target can't see Theme).
private enum WidgetPalette {
    static let purple = Color(red: 0.49, green: 0.36, blue: 0.99)
    static let mint = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let amber = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let blue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let cyan = Color(red: 0.0, green: 0.83, blue: 1.0)
    /// Soft amber for days below goal, instead of an alarming red.
    static let belowGoal = Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.6)
    /// Secondary text on the black activity background (meaningful text stays >= 0.6).
    static let secondaryText = Color.white.opacity(0.7)
}

private func phaseColor(for phase: Int) -> Color {
    switch phase {
    case 2: return WidgetPalette.blue
    case 3: return WidgetPalette.purple
    case 4: return WidgetPalette.amber
    default: return Color(white: 0.6)
    }
}

private func stateLabel(for stateRaw: String) -> String {
    (AvatarState(rawValue: stateRaw) ?? .neutral).description
}

private func stateColor(for stateRaw: String) -> Color {
    switch stateRaw {
    case "vital": return WidgetPalette.mint
    case "neutral": return WidgetPalette.cyan
    case "low": return WidgetPalette.amber
    default: return Color(white: 0.6)
    }
}

private func phaseIcon(for phase: Int) -> String {
    switch phase {
    case 1: return "circle"
    case 2: return "circle.fill"
    case 3: return "star.fill"
    case 4: return "sparkles"
    default: return "circle"
    }
}

private func phaseName(for phase: Int) -> String {
    switch phase {
    case 1: return "Seedling"
    case 2: return "Growing"
    case 3: return "Thriving"
    case 4: return "Legendary"
    default: return "Seedling"
    }
}

private let dailyGoal: Double = 7500.0

// MARK: - Lock Screen Live Activity
// Fixed 56pt sprite so the layout stays put when isWalking toggles.
// Right column: steps (headline) → goal progress bar → "N to goal · Phase" (footnote).

private struct LockScreenView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    private var phase: Int { context.state.currentPhase }

    private var goalProgress: Double {
        min(1, max(0, Double(context.state.steps) / dailyGoal))
    }

    private var goalText: String {
        let remaining = max(0, Int(dailyGoal) - context.state.steps)
        return remaining == 0 ? "Goal reached" : "\(remaining.formatted()) to goal"
    }

    private var phaseText: String {
        "Phase \(phase) \(phaseName(for: phase))"
    }

    var body: some View {
        HStack(spacing: 12) {
            AnimatedSpriteView(
                genderRaw: context.state.genderRaw,
                stateRaw: context.state.stateRaw,
                isWalking: context.state.isWalking,
                size: 56
            )
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                Group {
                    if let milestone = context.state.milestoneText {
                        Text(milestone)
                            .fontWeight(.bold)
                            .foregroundColor(WidgetPalette.gold)
                    } else {
                        Text("\(context.state.steps.formatted()) steps")
                            .foregroundColor(.white)
                    }
                }
                .font(.headline)
                .lineLimit(1)

                ProgressView(value: goalProgress)
                    .tint(phaseColor(for: phase))

                Text("\(goalText) · \(phaseText)")
                    .font(.footnote)
                    .foregroundColor(WidgetPalette.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel("\(goalText), \(phaseText)")
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .activityBackgroundTint(.black)
    }
}

// MARK: - Compact Views — "Steps Forward"

private struct CompactLeadingView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    var body: some View {
        AnimatedSpriteView(
            genderRaw: context.state.genderRaw,
            stateRaw: context.state.stateRaw,
            isWalking: context.state.isWalking,
            size: 24
        )
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    var body: some View {
        if let milestone = context.state.milestoneText {
            Text(milestone)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(WidgetPalette.gold)
        } else {
            HStack(spacing: 4) {
                Text(context.state.steps.formatted())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Circle()
                    .fill(stateColor(for: context.state.stateRaw))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Minimal View — "Progress Arc"

private struct MinimalView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    private var goalProgress: Double {
        min(Double(context.state.steps) / dailyGoal, 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                .frame(width: 24, height: 24)

            Circle()
                .trim(from: 0, to: goalProgress)
                .stroke(
                    stateColor(for: context.state.stateRaw),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))

            AnimatedSpriteView(
                genderRaw: context.state.genderRaw,
                stateRaw: context.state.stateRaw,
                isWalking: context.state.isWalking,
                size: 16
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(context.state.steps.formatted()) steps")
    }
}

// MARK: - Expanded DI — "Full Dashboard"
//
// Export (370x170):
//   Character:       (52, 18)  40x48  relY=10.6%
//   Steps:           (257, 24) 70x36  relY=14.1%
//   Phase:           (121, 24) 128x14 relY=14.1%
//   Progress Bar:    (20, 77)  330x4  relY=45.3%
//   Progress Labels: (20, 87)  330x13 relY=51.2%
//   Week Dots:       (20, 102) 330x14 relY=60.0%  ← ABOVE divider
//   Divider:         (20, 116) 330x1  relY=68.2%  ← BELOW dots
//
// Bottom order: bar → 6px → labels → 2px → dots → 0px → divider

// Leading: 40x48 character with badge overlaid
private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Circle()
                    .fill(stateColor(for: context.state.stateRaw).opacity(0.12))
                    .frame(width: 36, height: 36)

                AnimatedSpriteView(
                    genderRaw: context.state.genderRaw,
                    stateRaw: context.state.stateRaw,
                    isWalking: context.state.isWalking,
                    size: 28
                )
            }

            Text(stateLabel(for: context.state.stateRaw))
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .fixedSize()
                .foregroundColor(stateColor(for: context.state.stateRaw))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(stateColor(for: context.state.stateRaw).opacity(0.2))
                .clipShape(Capsule())
                .offset(y: 8)
        }
        .frame(minWidth: 40, minHeight: 44)
    }
}

// Trailing: 70x36 step count — font 20pt + "steps" caption2
private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if let milestone = context.state.milestoneText {
                Text(milestone)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(WidgetPalette.gold)
            } else {
                Text(context.state.steps.formatted())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("steps")
                    .font(.caption2)
                    .foregroundColor(WidgetPalette.secondaryText)
            }
        }
    }
}

// Center: 128x14 phase info
private struct ExpandedCenterView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: phaseIcon(for: context.state.currentPhase))
                .font(.caption2)
                .foregroundColor(phaseColor(for: context.state.currentPhase))
                .accessibilityHidden(true)
            Text("Phase \(context.state.currentPhase) • \(phaseName(for: context.state.currentPhase))")
                .font(.caption2.weight(.medium))
                .foregroundColor(phaseColor(for: context.state.currentPhase))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// Bottom: bar → 6px → labels → 2px → dots → 0px → divider
private struct ExpandedBottomView: View {
    let context: ActivityViewContext<PixelStepperAttributes>

    private var goalProgress: Double {
        min(Double(context.state.steps) / dailyGoal, 1.0)
    }

    private var stepsRemaining: Int {
        max(0, Int(dailyGoal) - context.state.steps)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar — h=4
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    stateColor(for: context.state.stateRaw),
                                    phaseColor(for: context.state.currentPhase)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * max(0, goalProgress), height: 4)
                }
            }
            .frame(height: 4)

            // 6px gap
            Spacer().frame(height: 6)

            // Progress labels — h=13
            HStack {
                Text("\(context.state.steps.formatted()) / \(Int(dailyGoal).formatted())")
                    .font(.caption2)
                    .foregroundColor(WidgetPalette.secondaryText)

                Spacer()

                if goalProgress >= 1.0 {
                    Text("Goal reached!")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(WidgetPalette.mint)
                } else {
                    Text("\(stepsRemaining.formatted()) to go")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(stateColor(for: context.state.stateRaw))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(height: 14)

            // 2px gap
            Spacer().frame(height: 2)

            // Week dots — h=14 (ABOVE divider per user layout)
            WeekDotsView()
                .frame(height: 14)

            // 0px gap — divider touches dots
            // Divider — h=1
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Week Dots (reads SharedData from App Group)

private struct WeekDotsView: View {
    private let weekData: [Int]

    init() {
        let data = SharedData.loadWeekData()
        if data.count >= 7 {
            self.weekData = Array(data.suffix(7))
        } else {
            self.weekData = data + Array(repeating: 0, count: max(0, 7 - data.count))
        }
    }

    var body: some View {
        HStack {
            Text("This week")
                .font(.caption2)
                .foregroundColor(WidgetPalette.secondaryText)

            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<min(weekData.count, 7), id: \.self) { index in
                    let isToday = index == weekData.count - 1
                    let steps = weekData[index]
                    let goalMet = steps >= 7500

                    ZStack {
                        Circle()
                            .fill(dotColor(goalMet: goalMet, isToday: isToday, hasData: steps > 0))
                            .frame(width: 6, height: 6)

                        if isToday {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 2, height: 2)
                        }
                    }
                }
            }
        }
    }

    private func dotColor(goalMet: Bool, isToday: Bool, hasData: Bool) -> Color {
        if isToday {
            return goalMet ? WidgetPalette.mint : WidgetPalette.blue
        }
        if !hasData {
            return Color.white.opacity(0.1)
        }
        return goalMet ? WidgetPalette.mint : WidgetPalette.belowGoal
    }
}
