import ActivityKit
import SwiftUI
import WidgetKit

struct PixelPalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PixelPalAttributes.self) { context in
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

// MARK: - Animated Sprite View (12fps via TimelineView)

private struct AnimatedSpriteView: View {
    let genderRaw: String
    let stateRaw: String
    let isWalking: Bool
    var size: CGFloat = 40

    var body: some View {
        TimelineView(.periodic(from: .now, by: isWalking ? 0.083 : 0.8)) { timeline in
            let frame = frameIndex(for: timeline.date)
            let name = spriteName(frame: frame)

            if let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
    }

    private func frameIndex(for date: Date) -> Int {
        if isWalking {
            let index = Int(date.timeIntervalSince1970 / 0.083)
            return (index % SpriteAssets.walkingFrameCount) + 1
        } else {
            let index = Int(date.timeIntervalSince1970 / 0.8)
            return (index % 2) + 1
        }
    }

    private func spriteName(frame: Int) -> String {
        if isWalking {
            return SpriteAssets.walkingSpriteName(genderRaw: genderRaw, frame: frame)
        }
        return SpriteAssets.spriteName(genderRaw: genderRaw, stateRaw: stateRaw, frame: frame)
    }
}

// MARK: - Color Helpers

private func phaseColor(for phase: Int) -> Color {
    switch phase {
    case 1: return .gray
    case 2: return .blue
    case 3: return .purple
    case 4: return .orange
    default: return .gray
    }
}

private func stateColor(for stateRaw: String) -> Color {
    switch stateRaw {
    case "vital": return .green
    case "neutral": return Color(red: 0.35, green: 0.78, blue: 0.98)
    case "low": return .orange
    default: return .gray
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
// Export: char (14,16) 50x56, steps (76,22) 100x20, stateInfo (76,48) 180x14

private struct LockScreenView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        HStack(spacing: 12) {
            AnimatedSpriteView(
                genderRaw: context.state.genderRaw,
                stateRaw: context.state.stateRaw,
                isWalking: context.state.isWalking,
                size: context.state.isWalking ? 80 : 50
            )

            VStack(alignment: .leading, spacing: 6) {
                if let milestone = context.state.milestoneText {
                    Text(milestone)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else {
                    Text("\(context.state.steps) steps")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(stateColor(for: context.state.stateRaw))
                        .frame(width: 5, height: 5)
                    Text(context.state.stateRaw.capitalized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.3))
                    Text("Phase \(context.state.currentPhase)")
                        .font(.system(size: 11))
                        .foregroundColor(phaseColor(for: context.state.currentPhase).opacity(0.8))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .activityBackgroundTint(.black)
    }
}

// MARK: - Compact Views — "Steps Forward"

private struct CompactLeadingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

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
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        if let milestone = context.state.milestoneText {
            Text(milestone)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
        } else {
            HStack(spacing: 4) {
                Text("\(context.state.steps)")
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
    let context: ActivityViewContext<PixelPalAttributes>

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
    let context: ActivityViewContext<PixelPalAttributes>

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

            Text(context.state.stateRaw.capitalized)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(stateColor(for: context.state.stateRaw))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(stateColor(for: context.state.stateRaw).opacity(0.2))
                .clipShape(Capsule())
                .offset(y: 8)
        }
        .frame(width: 40, height: 44)
    }
}

// Trailing: 70x36 step count — font 20pt + "steps" 8pt
private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if let milestone = context.state.milestoneText {
                Text(milestone)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            } else {
                Text("\(context.state.steps)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("steps")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Center: 128x14 phase info
private struct ExpandedCenterView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: phaseIcon(for: context.state.currentPhase))
                .font(.system(size: 8))
                .foregroundColor(phaseColor(for: context.state.currentPhase))
            Text("Phase \(context.state.currentPhase) • \(phaseName(for: context.state.currentPhase))")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(phaseColor(for: context.state.currentPhase).opacity(0.9))
        }
    }
}

// Bottom: bar → 6px → labels → 2px → dots → 0px → divider
private struct ExpandedBottomView: View {
    let context: ActivityViewContext<PixelPalAttributes>

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
                        .frame(width: geo.size.width * goalProgress, height: 4)
                }
            }
            .frame(height: 4)

            // 6px gap
            Spacer().frame(height: 6)

            // Progress labels — h=13
            HStack {
                Text("\(context.state.steps) / \(Int(dailyGoal).formatted())")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                Spacer()

                if goalProgress >= 1.0 {
                    Text("Goal reached!")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Text("\(stepsRemaining.formatted()) to go")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(stateColor(for: context.state.stateRaw))
                }
            }
            .frame(height: 13)

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
                .font(.system(size: 8))
                .foregroundColor(.secondary)

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
            return goalMet ? Color.green : Color.blue
        }
        if !hasData {
            return Color.white.opacity(0.1)
        }
        return goalMet ? Color.green : Color.red.opacity(0.6)
    }
}
