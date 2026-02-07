import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    /// Demo entry used for placeholder and gallery preview.
    static let demo = SimpleEntry(
        date: Date(),
        state: .neutral,
        gender: .male,
        phase: 1,
        steps: 4231,
        cumulativeSteps: 4231,
        weekData: [6200, 8100, 3400, 7800, 5100, 9200, 4231]
    )

    func placeholder(in context: Context) -> SimpleEntry {
        Self.demo
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Always return demo data for gallery preview to guarantee visible content
        if context.isPreview {
            completion(Self.demo)
            return
        }
        completion(Self.loadEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = Self.loadEntry(date: Date())
        // Single entry, refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Loads entry from SharedData with safe fallbacks.
    private static func loadEntry(date: Date) -> SimpleEntry {
        let state = SharedData.loadState()
        let gender = SharedData.loadGender() ?? .male
        let phase = SharedData.loadPhase()
        let steps = SharedData.loadSteps()
        let cumulativeSteps = SharedData.loadCumulativeSteps()
        let weekData = SharedData.loadWeekData()

        return SimpleEntry(
            date: date,
            state: state,
            gender: gender,
            phase: max(1, phase),
            steps: steps,
            cumulativeSteps: cumulativeSteps,
            weekData: weekData.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : weekData
        )
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let state: AvatarState
    let gender: Gender
    let phase: Int
    let steps: Int
    let cumulativeSteps: Int
    let weekData: [Int]
}

// MARK: - Color & Phase Helpers

private func widgetStateColor(for state: AvatarState) -> Color {
    switch state {
    case .vital: return .green
    case .neutral: return Color(red: 0.35, green: 0.78, blue: 0.98)
    case .low: return .orange
    }
}

private func widgetPhaseColor(for phase: Int) -> Color {
    switch phase {
    case 1: return Color(white: 0.7)
    case 2: return Color(red: 0.4, green: 0.6, blue: 1.0)
    case 3: return Color(red: 0.7, green: 0.4, blue: 1.0)
    case 4: return .orange
    default: return Color(white: 0.7)
    }
}

private func widgetPhaseIcon(for phase: Int) -> String {
    switch phase {
    case 1: return "circle"
    case 2: return "circle.fill"
    case 3: return "star.fill"
    case 4: return "sparkles"
    default: return "circle"
    }
}

private func widgetPhaseName(for phase: Int) -> String {
    switch phase {
    case 1: return "Seedling"
    case 2: return "Growing"
    case 3: return "Thriving"
    case 4: return "Legendary"
    default: return "Seedling"
    }
}

// MARK: - Small Widget View
// Export (170x170): char (45,18) 80x80, steps (35,104) 100x24, phase (30,132) 110x16

struct PixelPalSmallWidgetView: View {
    var entry: Provider.Entry

    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        VStack(spacing: 0) {
            Image(spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)

            Spacer().frame(height: 6)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.steps)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("steps")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .frame(height: 24)

            Spacer().frame(height: 4)

            HStack(spacing: 4) {
                Image(systemName: widgetPhaseIcon(for: entry.phase))
                    .font(.system(size: 9))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
                Text("Phase \(entry.phase)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
            }
            .frame(height: 16)
        }
    }
}

// MARK: - Medium Widget View
// Export (364x170): char (16,24) 72x80, steps (104,24) 100x32,
//   bar (104,64) 240x4, labels (104,72) 240x12,
//   chart (104,90) 240x36, phase (104,132) 140x14

struct PixelPalMediumWidgetView: View {
    var entry: Provider.Entry

    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    private var dailyGoal: Double { 7500.0 }

    private var goalProgress: Double {
        min(Double(entry.steps) / dailyGoal, 1.0)
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        HStack(spacing: 16) {
            // Left: Character with glow + badge overlay
            ZStack(alignment: .bottom) {
                ZStack {
                    Circle()
                        .fill(widgetStateColor(for: entry.state).opacity(0.25))
                        .frame(width: 68, height: 68)

                    Image(spriteName)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 52, height: 52)
                }

                Text(entry.state.rawValue.capitalized)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(widgetStateColor(for: entry.state))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(widgetStateColor(for: entry.state).opacity(0.3))
                    .clipShape(Capsule())
                    .offset(y: 8)
            }
            .frame(width: 72, height: 80)

            // Right: Stats + progress + chart + phase
            VStack(alignment: .leading, spacing: 0) {
                // Steps count — h=32
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.steps)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("steps")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .frame(height: 32)

                // Gap to progress bar
                Spacer().frame(height: 8)

                // Daily goal progress bar — h=4
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [widgetStateColor(for: entry.state), widgetPhaseColor(for: entry.phase)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, geo.size.width * goalProgress), height: 4)
                    }
                }
                .frame(height: 4)

                Spacer().frame(height: 4)

                // Bar labels — h=12
                HStack {
                    Text("\(Int(goalProgress * 100))%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(widgetStateColor(for: entry.state))
                    Spacer()
                    Text("\(entry.steps)/\(Int(dailyGoal).formatted())")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .frame(height: 12)

                Spacer().frame(height: 6)

                // Mini week bar chart — h=36
                MiniBarChart(data: entry.weekData.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : entry.weekData)
                    .frame(height: 36)

                Spacer().frame(height: 6)

                // Phase info — h=14
                HStack(spacing: 3) {
                    Image(systemName: widgetPhaseIcon(for: entry.phase))
                        .font(.system(size: 8))
                        .foregroundStyle(widgetPhaseColor(for: entry.phase))
                    Text("Phase \(entry.phase) • \(widgetPhaseName(for: entry.phase))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(widgetPhaseColor(for: entry.phase))
                }
                .frame(height: 14)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Large Widget View
// Export (364x376): char (132,16) 100x100, steps (102,124) 160x42,
//   bar (24,178) 316x6, labels (24,190) 316x14,
//   chart (24,218) 316x70, dayLabels (24,292) 316x14,
//   phase (112,316) 140x16, weekDots (24,342) 316x16

struct PixelPalLargeWidgetView: View {
    var entry: Provider.Entry

    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    private var dailyProgress: Double {
        min(Double(entry.steps) / 7500.0, 1.0)
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        VStack(spacing: 0) {
            // Character — 100x100
            ZStack {
                Circle()
                    .fill(widgetPhaseColor(for: entry.phase).opacity(0.25))
                    .frame(width: 94, height: 94)

                Image(spriteName)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
            .frame(width: 100, height: 100)

            Spacer().frame(height: 8)

            // Steps hero number — h=42
            VStack(spacing: 2) {
                Text("\(entry.steps)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(entry.state.rawValue.capitalized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(widgetStateColor(for: entry.state))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(widgetStateColor(for: entry.state).opacity(0.25))
                    .clipShape(Capsule())
            }
            .frame(height: 42)

            Spacer().frame(height: 12)

            // Daily progress bar — h=6
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [widgetStateColor(for: entry.state), widgetPhaseColor(for: entry.phase)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geometry.size.width * dailyProgress), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)

            Spacer().frame(height: 6)

            // Bar labels — h=14
            HStack {
                Text("\(entry.steps) / 7,500")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                Spacer()
                if dailyProgress >= 1.0 {
                    Text("Goal reached!")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.green)
                } else {
                    Text("\(max(0, 7500 - entry.steps).formatted()) to go")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(widgetStateColor(for: entry.state))
                }
            }
            .frame(height: 14)
            .padding(.horizontal, 24)

            Spacer().frame(height: 10)

            // Week bar chart — h=70 (always show, use placeholder if empty)
            WeekBarChart(data: entry.weekData.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : entry.weekData)
                .frame(height: 70)
                .padding(.horizontal, 24)

            Spacer().frame(height: 4)

            // Day labels — h=14
            HStack(spacing: 0) {
                ForEach(dayLabels(), id: \.self) { label in
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 14)
            .padding(.horizontal, 24)

            Spacer().frame(height: 8)

            // Phase info — h=16
            HStack(spacing: 4) {
                Image(systemName: widgetPhaseIcon(for: entry.phase))
                    .font(.system(size: 9))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
                Text("Phase \(entry.phase) • \(widgetPhaseName(for: entry.phase))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
            }
            .frame(height: 16)

            Spacer().frame(height: 6)

            // Week dots — h=16
            WidgetWeekDotsView(weekData: entry.weekData)
                .frame(height: 16)
                .padding(.horizontal, 24)
        }
    }

    private func dayLabels() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        let labels = ["S", "M", "T", "W", "T", "F", "S"]
        var result: [String] = []
        for offset in -6...0 {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                result.append(labels[weekday - 1])
            }
        }
        return result
    }
}

// MARK: - Mini Bar Chart (for medium widget)

private struct MiniBarChart: View {
    let data: [Int]
    private let maxSteps = 10000

    var body: some View {
        let weekSlice = Array(data.suffix(7))
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(weekSlice.enumerated()), id: \.offset) { index, steps in
                    let isToday = index == weekSlice.count - 1
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barColor(steps: steps, isToday: isToday))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(3, CGFloat(steps) / CGFloat(maxSteps) * geo.size.height))
                }
            }
        }
    }

    private func barColor(steps: Int, isToday: Bool) -> Color {
        if isToday { return Color.gray }
        if steps >= 7500 { return .green }
        if steps > 0 { return Color.red.opacity(0.7) }
        return Color.white.opacity(0.15)
    }
}

// MARK: - Week Bar Chart (for large widget)

private struct WeekBarChart: View {
    let data: [Int]
    private let maxSteps = 10000

    var body: some View {
        let weekSlice = Array(data.suffix(7))
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(weekSlice.enumerated()), id: \.offset) { index, steps in
                    let isToday = index == weekSlice.count - 1
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(steps: steps, isToday: isToday))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(3, CGFloat(steps) / CGFloat(maxSteps) * geo.size.height))
                }
            }
        }
    }

    private func barColor(steps: Int, isToday: Bool) -> Color {
        if isToday { return Color.gray }
        if steps >= 7500 { return .green }
        if steps > 0 { return Color.red.opacity(0.7) }
        return Color.white.opacity(0.15)
    }
}

// MARK: - Widget Week Dots (for large widget)

private struct WidgetWeekDotsView: View {
    let weekData: [Int]

    private var paddedData: [Int] {
        if weekData.count >= 7 {
            return Array(weekData.suffix(7))
        }
        return weekData + Array(repeating: 0, count: max(0, 7 - weekData.count))
    }

    var body: some View {
        HStack {
            Text("This week")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))

            Spacer()

            HStack(spacing: 5) {
                ForEach(0..<min(paddedData.count, 7), id: \.self) { index in
                    let isToday = index == paddedData.count - 1
                    let steps = paddedData[index]
                    let goalMet = steps >= 7500

                    ZStack {
                        Circle()
                            .fill(dotColor(goalMet: goalMet, isToday: isToday, hasData: steps > 0))
                            .frame(width: 8, height: 8)

                        if isToday {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 3, height: 3)
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
            return Color.white.opacity(0.2)
        }
        return goalMet ? Color.green : Color.red.opacity(0.6)
    }
}

// MARK: - Accessory Widget Views (Lock Screen)

struct PixelPalAccessoryCircularView: View {
    var entry: Provider.Entry

    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    private var goalProgress: Double {
        min(Double(entry.steps) / 7500.0, 1.0)
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        ZStack {
            AccessoryWidgetBackground()

            // Progress arc
            Circle()
                .trim(from: 0, to: goalProgress)
                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(2)

            Image(spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .padding(6)
        }
    }
}

struct PixelPalAccessoryRectangularView: View {
    var entry: Provider.Entry

    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        HStack(spacing: 8) {
            Image(spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                // Steps + state dot
                HStack(spacing: 4) {
                    Text("\(entry.steps) steps")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Circle()
                        .fill(widgetStateColor(for: entry.state))
                        .frame(width: 5, height: 5)
                }

                // Phase info
                HStack(spacing: 3) {
                    Image(systemName: widgetPhaseIcon(for: entry.phase))
                        .font(.system(size: 8))
                    Text("Phase \(entry.phase) • \(widgetPhaseName(for: entry.phase))")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .lineLimit(1)
    }
}

struct PixelPalAccessoryInlineView: View {
    var entry: Provider.Entry

    var body: some View {
        Label("Pixel Pace Phase \(entry.phase)", systemImage: widgetPhaseIcon(for: entry.phase))
    }
}

// MARK: - Home Screen Widget

struct PixelPalHomeWidget: Widget {
    let kind: String = "PixelPalWidget"

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.04, blue: 0.12),
                Color(red: 0.1, green: 0.04, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PixelPalHomeWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        gradient
                    }
            } else {
                PixelPalHomeWidgetView(entry: entry)
                    .padding()
                    .background(gradient)
            }
        }
        .configurationDisplayName("Pixel Pace")
        .description("Your ambient walking companion.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Routes to the correct widget size view.
struct PixelPalHomeWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemMedium:
                PixelPalMediumWidgetView(entry: entry)
            case .systemLarge:
                PixelPalLargeWidgetView(entry: entry)
            default:
                PixelPalSmallWidgetView(entry: entry)
            }
        }
        .unredacted()
    }
}

// MARK: - Lock Screen Widgets

struct PixelPalLockScreenWidget: Widget {
    let kind: String = "PixelPalLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PixelPalLockScreenView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                PixelPalLockScreenView(entry: entry)
            }
        }
        .configurationDisplayName("Pixel Pace")
        .description("Your Pixel Pace character on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct PixelPalLockScreenView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            PixelPalAccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            PixelPalAccessoryRectangularView(entry: entry)
        case .accessoryInline:
            PixelPalAccessoryInlineView(entry: entry)
        default:
            PixelPalSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct PixelPalWidgetBundle: WidgetBundle {
    var body: some Widget {
        PixelPalHomeWidget()
        PixelPalLockScreenWidget()
        PixelPalLiveActivity()
    }
}
