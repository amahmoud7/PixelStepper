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
        weekData: [6200, 8100, 3400, 7800, 5100, 9200, 4231],
        cosmeticBackground: nil,
        cosmeticHat: nil,
        cosmeticAccessory: nil,
        cosmeticSkin: nil
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
        let now = Date()
        let entry = Self.loadEntry(date: now)
        // Data only changes when the app pushes a reload, so refresh hourly at most,
        // and always at midnight so today's count resets to 0.
        let calendar = Calendar.current
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
            ?? now.addingTimeInterval(3600)
        let nextUpdate = min(now.addingTimeInterval(3600), startOfTomorrow)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Loads entry from SharedData with safe fallbacks.
    /// Data saved on an earlier day is stale: today's steps read as 0.
    private static func loadEntry(date: Date) -> SimpleEntry {
        let calendar = Calendar.current
        let lastUpdate = SharedData.loadLastUpdateDate()
        let isFresh = lastUpdate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        let state = isFresh ? SharedData.loadState() : .low
        let gender = SharedData.loadGender() ?? .male
        let phase = SharedData.loadPhase()
        let steps = isFresh ? SharedData.loadSteps() : 0
        let cumulativeSteps = SharedData.loadCumulativeSteps()
        var weekData = SharedData.loadWeekData()
        let cosmetics = SharedData.loadEquippedCosmetics()

        // Shift the week so its last element is today rather than the last update day.
        if let lastUpdate, !isFresh, !weekData.isEmpty {
            let daysStale = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastUpdate),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            if daysStale > 0 {
                weekData = Array((weekData + Array(repeating: 0, count: min(daysStale, 7))).suffix(7))
            }
        }

        return SimpleEntry(
            date: date,
            state: state,
            gender: gender,
            phase: max(1, phase),
            steps: steps,
            cumulativeSteps: cumulativeSteps,
            weekData: weekData.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : weekData,
            cosmeticBackground: cosmetics.background,
            cosmeticHat: cosmetics.hat,
            cosmeticAccessory: cosmetics.accessory,
            cosmeticSkin: cosmetics.skin
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
    let cosmeticBackground: String?
    let cosmeticHat: String?
    let cosmeticAccessory: String?
    let cosmeticSkin: String?
}

// MARK: - Color & Phase Helpers

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
}

private func widgetStateColor(for state: AvatarState) -> Color {
    switch state {
    case .vital: return WidgetPalette.mint
    case .neutral: return WidgetPalette.cyan
    case .low: return WidgetPalette.amber
    }
}

private func widgetPhaseColor(for phase: Int) -> Color {
    switch phase {
    case 2: return WidgetPalette.blue
    case 3: return WidgetPalette.purple
    case 4: return WidgetPalette.amber
    default: return Color(white: 0.6)
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

private func widgetGoalProgress(for steps: Int) -> Double {
    min(1, max(0, Double(steps) / 7500.0))
}

/// Rounded goal bar: white track with a state → phase gradient fill.
private struct WidgetProgressBar: View {
    let progress: Double
    let state: AvatarState
    let phase: Int
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [widgetStateColor(for: state), widgetPhaseColor(for: phase)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geo.size.width * progress))
            }
        }
        .frame(height: height)
    }
}

private func widgetEnergyLabel(for state: AvatarState) -> String {
    switch state {
    case .vital: return "Vital energy"
    case .neutral: return "Neutral energy"
    case .low: return "Low energy"
    }
}

/// Single VoiceOver summary for a widget, e.g. "Pixel Stepper, 4,210 steps, Neutral energy, Phase 1 Seedling".
private func widgetAccessibilityLabel(for entry: SimpleEntry) -> String {
    "Pixel Stepper, \(entry.steps.formatted()) steps, \(widgetEnergyLabel(for: entry.state)), Phase \(entry.phase) \(widgetPhaseName(for: entry.phase))"
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
            ZStack {
                if let skinAsset = entry.cosmeticSkin {
                    // Full skin replacement
                    Image(decorative: skinAsset)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                } else {
                    // Cosmetic background or default
                    if let bgAsset = entry.cosmeticBackground {
                        Image(decorative: bgAsset)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 80, height: 80)
                    }

                    Image(decorative: spriteName)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)

                    // Cosmetic hat
                    if let hatAsset = entry.cosmeticHat {
                        Image(decorative: hatAsset)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 48, height: 48)
                            .offset(y: -24)
                    }

                    // Cosmetic accessory
                    if let accAsset = entry.cosmeticAccessory {
                        Image(decorative: accAsset)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 40, height: 40)
                            .offset(x: 20)
                    }
                }
            }
            .frame(width: 80, height: 80)

            Spacer().frame(height: 4)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(entry.steps.formatted())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("steps")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .frame(height: 24)

            Spacer().frame(height: 4)

            WidgetProgressBar(
                progress: widgetGoalProgress(for: entry.steps),
                state: entry.state,
                phase: entry.phase
            )
            .frame(width: 100)

            Spacer().frame(height: 4)

            HStack(spacing: 4) {
                Image(systemName: widgetPhaseIcon(for: entry.phase))
                    .font(.system(size: 11))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
                Text("Phase \(entry.phase)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(for: entry))
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
            // Left: Character with glow + cosmetics + badge overlay
            ZStack(alignment: .bottom) {
                ZStack {
                    if let skinAsset = entry.cosmeticSkin {
                        // Full skin replacement
                        Image(decorative: skinAsset)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 52, height: 52)
                    } else {
                        // Cosmetic background or default glow
                        if let bgAsset = entry.cosmeticBackground {
                            Image(decorative: bgAsset)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 68, height: 68)
                        } else {
                            Circle()
                                .fill(widgetStateColor(for: entry.state).opacity(0.25))
                                .frame(width: 68, height: 68)
                        }

                        Image(decorative: spriteName)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 52, height: 52)

                        // Cosmetic hat
                        if let hatAsset = entry.cosmeticHat {
                            Image(decorative: hatAsset)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 32, height: 32)
                                .offset(y: -16)
                        }

                        // Cosmetic accessory
                        if let accAsset = entry.cosmeticAccessory {
                            Image(decorative: accAsset)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 26, height: 26)
                                .offset(x: 13)
                        }
                    }
                }

                Text(entry.state.description)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
                    Text(entry.steps.formatted())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("steps")
                        .font(.system(size: 11))
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
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(widgetStateColor(for: entry.state))
                    Spacer()
                    Text("\(entry.steps.formatted())/\(Int(dailyGoal).formatted())")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: 14)

                Spacer().frame(height: 6)

                // Mini week bar chart — h=36
                MiniBarChart(data: entry.weekData.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : entry.weekData)
                    .frame(height: 36)

                Spacer().frame(height: 6)

                // Phase info — h=14
                HStack(spacing: 3) {
                    Image(systemName: widgetPhaseIcon(for: entry.phase))
                        .font(.system(size: 11))
                        .foregroundStyle(widgetPhaseColor(for: entry.phase))
                    Text("Phase \(entry.phase) • \(widgetPhaseName(for: entry.phase))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(widgetPhaseColor(for: entry.phase))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(height: 14)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(for: entry))
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
                if let skinAsset = entry.cosmeticSkin {
                    // Full skin replacement
                    Image(decorative: skinAsset)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                } else {
                    // Cosmetic background or default glow
                    if let bgAsset = entry.cosmeticBackground {
                        Image(decorative: bgAsset)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 94, height: 94)
                    } else {
                        Circle()
                            .fill(widgetPhaseColor(for: entry.phase).opacity(0.25))
                            .frame(width: 94, height: 94)
                    }

                    Image(decorative: spriteName)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)

                    // Cosmetic hat
                    if let hatAsset = entry.cosmeticHat {
                        Image(decorative: hatAsset)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 48, height: 48)
                            .offset(y: -24)
                    }

                    // Cosmetic accessory
                    if let accAsset = entry.cosmeticAccessory {
                        Image(decorative: accAsset)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 40, height: 40)
                            .offset(x: 20)
                    }
                }
            }
            .frame(width: 100, height: 100)

            Spacer().frame(height: 6)

            // Steps hero number + state capsule — sized to fit (~57pt)
            VStack(spacing: 2) {
                Text(entry.steps.formatted())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(entry.state.description)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(widgetStateColor(for: entry.state))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(widgetStateColor(for: entry.state).opacity(0.25))
                    .clipShape(Capsule())
            }

            Spacer().frame(height: 8)

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
                Text("\(entry.steps.formatted()) / \(7500.formatted())")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                Spacer()
                if dailyProgress >= 1.0 {
                    Text("Goal reached!")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WidgetPalette.mint)
                } else {
                    Text("\(max(0, 7500 - entry.steps).formatted()) to go")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(widgetStateColor(for: entry.state))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
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
                // Labels repeat ("S", "T"), so identify by position.
                ForEach(Array(dayLabels().enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 14)
            .padding(.horizontal, 24)

            Spacer().frame(height: 8)

            // Phase info — h=16
            HStack(spacing: 4) {
                Image(systemName: widgetPhaseIcon(for: entry.phase))
                    .font(.system(size: 11))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
                Text("Phase \(entry.phase) • \(widgetPhaseName(for: entry.phase))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(widgetPhaseColor(for: entry.phase))
            }
            .frame(height: 16)

            Spacer().frame(height: 6)

            // Week dots — h=16
            WidgetWeekDotsView(weekData: entry.weekData)
                .frame(height: 16)
                .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(for: entry))
    }

    private func dayLabels() -> [String] {
        let calendar = Calendar.current
        let today = entry.date
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
                        .frame(height: max(3, min(1, CGFloat(steps) / CGFloat(maxSteps)) * geo.size.height))
                }
            }
        }
    }

    private func barColor(steps: Int, isToday: Bool) -> Color {
        if isToday { return Color.gray }
        if steps >= 7500 { return WidgetPalette.mint }
        if steps > 0 { return WidgetPalette.belowGoal }
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
                        .frame(height: max(3, min(1, CGFloat(steps) / CGFloat(maxSteps)) * geo.size.height))
                }
            }
        }
    }

    private func barColor(steps: Int, isToday: Bool) -> Color {
        if isToday { return Color.gray }
        if steps >= 7500 { return WidgetPalette.mint }
        if steps > 0 { return WidgetPalette.belowGoal }
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
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))

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
            return goalMet ? WidgetPalette.mint : WidgetPalette.blue
        }
        if !hasData {
            return Color.white.opacity(0.2)
        }
        return goalMet ? WidgetPalette.mint : WidgetPalette.belowGoal
    }
}

// MARK: - Accessory Widget Views (Lock Screen)

struct PixelPalAccessoryCircularView: View {
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

        Gauge(value: widgetGoalProgress(for: entry.steps)) {
            EmptyView()
        } currentValueLabel: {
            Image(decorative: spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .padding(2)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(for: entry))
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
            Image(decorative: spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                // Steps + state dot
                HStack(spacing: 4) {
                    Text("\(entry.steps.formatted()) steps")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Circle()
                        .fill(widgetStateColor(for: entry.state))
                        .frame(width: 5, height: 5)
                }

                // Phase info
                HStack(spacing: 3) {
                    Image(systemName: widgetPhaseIcon(for: entry.phase))
                        .font(.system(size: 10))
                    Text("Phase \(entry.phase) • \(widgetPhaseName(for: entry.phase))")
                        .font(.system(size: 11, weight: .medium))
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(for: entry))
    }
}

struct PixelPalAccessoryInlineView: View {
    var entry: Provider.Entry

    var body: some View {
        Label("\(entry.steps.formatted()) steps", systemImage: "figure.walk")
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
                // Fill the whole widget so white text never lands on the system background.
                PixelPalHomeWidgetView(entry: entry)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(gradient)
            }
        }
        .configurationDisplayName("Pixel Stepper")
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
        .configurationDisplayName("Pixel Stepper")
        .description("Your Pixel Stepper character on the Lock Screen.")
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
