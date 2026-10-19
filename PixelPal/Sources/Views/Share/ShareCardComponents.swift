import SwiftUI

// MARK: - Share Card Background View

struct ShareCardBackgroundView: View {
    let background: ShareCardBackground
    let format: ShareCardFormat

    var body: some View {
        switch background {
        case .darkGlow:
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.1, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.1, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunset:
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.4, blue: 0.2),
                    Color(red: 0.85, green: 0.2, blue: 0.4),
                    Color(red: 0.4, green: 0.1, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ocean:
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.3, blue: 0.5),
                    Color(red: 0.0, green: 0.15, blue: 0.4),
                    Color(red: 0.05, green: 0.1, blue: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .retro:
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.05),
                    Color(red: 0.25, green: 0.15, blue: 0.05),
                    Color(red: 0.15, green: 0.1, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .transparent:
            Color.clear
        }
    }
}

// MARK: - Watermark View

struct WatermarkView: View {
    var body: some View {
        Text("@officialpixelstepper")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.bottom, 24)
    }
}

// MARK: - Share Progress Bar (Widget Style)

struct ShareProgressBar: View {
    let progress: Double
    let stateColor: Color
    let phaseColor: Color

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.3))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [stateColor, phaseColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Share State Badge (Widget Style)

struct ShareStateBadge: View {
    let state: AvatarState
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(state.description)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.4))
        .clipShape(Capsule())
    }
}

// MARK: - Share Week Dots (Widget Style)

struct ShareWeekDots: View {
    let days: [DailyHistory.DayViewData]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(days) { day in
                ZStack {
                    Circle()
                        .fill(dotColor(for: day))
                        .frame(width: 8, height: 8)

                    if day.isToday {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
    }

    private func dotColor(for day: DailyHistory.DayViewData) -> Color {
        if day.isToday {
            return day.steps >= 7500 ? Color(hex: "#34C759") : .blue
        }
        guard day.hasData else { return Color.white.opacity(0.4) }

        if day.steps >= 7500 {
            return Color(hex: "#34C759")
        } else if day.steps >= 2500 {
            return .yellow
        } else {
            return Color(hex: "#FFB34D") // soft amber, never red
        }
    }
}

// MARK: - Share Phase Badge (Widget Style)

struct SharePhaseBadge: View {
    let phase: Int
    let name: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("Phase \(phase) \u{2022} \(name)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.4))
        .clipShape(Capsule())
    }
}

// MARK: - Share Bar Chart View (Widget Style Colors)

struct ShareBarChartView: View {
    let days: [DailyHistory.DayViewData]
    var barHeight: CGFloat = 100

    private var maxSteps: Int {
        max(days.map(\.steps).max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(days) { day in
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: day))
                        .frame(height: max(3, barHeight * CGFloat(day.steps) / CGFloat(maxSteps)))

                    Text(dayLabel(for: day.date))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func barColor(for day: DailyHistory.DayViewData) -> Color {
        guard day.hasData else { return Color.white.opacity(0.3) }

        if day.steps >= 7500 {
            return Color(hex: "#34C759") // green — vital
        } else if day.steps >= 2500 {
            return .yellow // yellow — neutral
        } else {
            return Color(hex: "#FFB34D") // soft amber — below goal (no-shame)
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let label = formatter.string(from: date)
        return String(label.prefix(2))
    }
}

// MARK: - Share Avatar View

/// Static sprite renderer for share cards — no timers or animation.
struct ShareAvatarView: View {
    let gender: Gender
    let state: AvatarState
    let phase: Int
    var spriteFrame: Int = 1
    var size: CGFloat = 160

    private var phaseColor: Color {
        switch phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [phaseColor.opacity(0.6), .clear],
                    center: .center,
                    startRadius: size * 0.1,
                    endRadius: size * 0.55
                ))
                .frame(width: size * 1.2, height: size * 1.2)

            Image(SpriteAssets.spriteName(gender: gender, state: state, frame: spriteFrame))
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Confetti Overlay

struct ConfettiOverlay: View {
    let size: CGSize

    private let sparkles: [(x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat)] = [
        (0.15, 0.12, 15, 0.8),
        (0.85, 0.08, -20, 0.6),
        (0.08, 0.35, 45, 0.7),
        (0.92, 0.3, -30, 0.9),
        (0.2, 0.55, 10, 0.5),
        (0.8, 0.52, -45, 0.7),
        (0.12, 0.75, 25, 0.6),
        (0.88, 0.7, -15, 0.8),
        (0.5, 0.05, 0, 0.5),
        (0.35, 0.85, 30, 0.6),
        (0.65, 0.82, -25, 0.7),
    ]

    var body: some View {
        ZStack {
            ForEach(sparkles.indices, id: \.self) { i in
                let sparkle = sparkles[i]
                Image(systemName: "sparkle")
                    .font(.system(size: 14 * sparkle.scale))
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(sparkle.rotation))
                    .position(
                        x: size.width * sparkle.x,
                        y: size.height * sparkle.y
                    )
            }
        }
        .allowsHitTesting(false)
    }
}
