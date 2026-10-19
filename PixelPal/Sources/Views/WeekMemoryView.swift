import SwiftUI

/// 7-Day Memory UI component (v1.1).
/// Shows rolling 7-day window with 6 past days + today indicator.
///
/// Design:
/// - 24pt circles with 12pt spacing
/// - Theme.goalMet = met goal
/// - Theme.belowGoal = below goal (soft amber, never red)
/// - Theme.today pulse = today
/// - Spring fill animation on state change
struct WeekMemoryView: View {
    /// Day view data from HistoryManager.
    let days: [DailyHistory.DayViewData]

    /// Whether today's goal was just met (triggers pulse animation).
    let justMetGoal: Bool

    /// Animation state for fills.
    @State private var animatedDays: [Bool] = []

    /// Pulse animation state for today.
    @State private var isPulsing: Bool = false

    /// Day key of the last "today" pulse, so it plays once per day rather than on every tab switch.
    @AppStorage("lastTodayPulseDay") private var lastTodayPulseDay: String = ""

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Space.m) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                let isShown = reduceMotion || (animatedDays.indices.contains(index) && animatedDays[index])
                DayBubble(
                    day: day,
                    isPulsing: day.isToday && (justMetGoal || isPulsing)
                )
                .scaleEffect(isShown ? 1.0 : 0.1)
                .opacity(isShown ? 1.0 : 0.0)
                .motion(
                    Motion.staggered(index, Motion.snappy),
                    value: animatedDays
                )
            }
        }
        .onAppear {
            // Start pulse for today (at most once per day)
            startPulseIfToday()

            // Pop-in only on first appearance, not on every tab switch.
            guard animatedDays.isEmpty else { return }
            animatedDays = Array(repeating: false, count: days.count)

            // Trigger animations (the per-bubble .motion drives the spring)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatedDays = Array(repeating: true, count: days.count)
            }
        }
        .onChange(of: days) { _ in
            startPulseIfToday()
        }
        .onChange(of: justMetGoal) { newValue in
            if newValue {
                triggerPulse()
            }
        }
    }

    private func startPulseIfToday() {
        guard let today = days.last, today.isToday else { return }
        let key = DailyGoalState.dayKey(for: Date())
        guard lastTodayPulseDay != key else { return }
        lastTodayPulseDay = key
        triggerPulse()
    }

    private func triggerPulse() {
        isPulsing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPulsing = false
        }
    }
}

// MARK: - Day Bubble

private struct DayBubble: View {
    let day: DailyHistory.DayViewData
    let isPulsing: Bool

    /// Bubble size.
    private let bubbleSize: CGFloat = 24

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Drives the expanding ring; reset to false before each pulse so it animates from rest.
    @State private var ring = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)
                .frame(width: bubbleSize, height: bubbleSize)

            // Pulse ring for today (kept in the tree so the animation has a start state)
            if day.isToday {
                Circle()
                    .stroke(bubbleColor, lineWidth: 2)
                    .frame(width: bubbleSize + 8, height: bubbleSize + 8)
                    .scaleEffect(ring ? 1.25 : 1.0)
                    .opacity(ring ? 0 : (isPulsing ? 1 : 0))
            }

            // Inner indicator dot for today
            if day.isToday {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
            }

            // Checkmark for goal met (past days). Fixed size: the bubble is a fixed 24pt circle.
            if !day.isToday && day.isGoalMet && day.hasData {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .onAppear {
            if isPulsing { pulse() }
        }
        .onChange(of: isPulsing) { newValue in
            if newValue { pulse() }
        }
    }

    private func pulse() {
        guard day.isToday, !reduceMotion else { return }
        ring = false
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.6).repeatCount(3, autoreverses: false)) {
                ring = true
            }
        }
    }

    private var accessibilityText: String {
        let prefix = day.isToday ? "Today" : day.date.formatted(.dateTime.weekday(.wide))
        guard day.hasData else { return "\(prefix), no data" }
        let status = day.isGoalMet ? ", goal met" : (day.isToday ? "" : ", below goal")
        return "\(prefix), \(day.steps.formatted()) steps\(status)"
    }

    private var backgroundColor: Color {
        if day.isToday {
            // Today uses the today tint with goal status fill
            if day.isGoalMet {
                return Theme.goalMet
            } else {
                return Theme.today.opacity(0.3)
            }
        } else {
            // Past days
            if !day.hasData {
                // No data yet (future or missing)
                return Theme.noData
            } else if day.isGoalMet {
                return Theme.goalMet
            } else {
                return Theme.belowGoal
            }
        }
    }

    private var bubbleColor: Color {
        if day.isGoalMet {
            return Theme.goalMet
        } else {
            return Theme.today
        }
    }
}

// MARK: - Mini Week View (for Live Activity)

/// Compact 7-day view for Live Activity/Dynamic Island.
struct MiniWeekMemoryView: View {
    let days: [DailyHistory.DayViewData]

    /// Smaller size for compact display.
    private let bubbleSize: CGFloat = 12
    private let spacing: CGFloat = 4

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(days) { day in
                MiniDayBubble(day: day)
            }
        }
    }
}

private struct MiniDayBubble: View {
    let day: DailyHistory.DayViewData
    private let bubbleSize: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .fill(miniBackgroundColor)
                .frame(width: bubbleSize, height: bubbleSize)

            // White dot for today
            if day.isToday {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
            }
        }
    }

    private var miniBackgroundColor: Color {
        if day.isToday {
            return day.isGoalMet ? Theme.goalMet : Theme.today
        } else if !day.hasData {
            return Theme.noData
        } else if day.isGoalMet {
            return Theme.goalMet
        } else {
            return Theme.belowGoal
        }
    }
}

// MARK: - Week Memory Section

/// Full section view for ContentView with label.
struct WeekMemorySection: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var justMetGoal: Bool = false

    /// Day key of the last goal-met pulse, so the celebration ring plays once per day.
    @AppStorage("lastGoalPulseDay") private var lastGoalPulseDay: String = ""

    var body: some View {
        VStack(spacing: 12) {
            // Week bubbles
            WeekMemoryView(
                days: historyManager.last7Days(),
                justMetGoal: justMetGoal
            )

            // Legend
            HStack(spacing: Space.l) {
                legendItem(color: Theme.goalMet, label: "Met")
                legendItem(color: Theme.belowGoal, label: "Below goal")
                legendItem(color: Theme.today, label: "Today")
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.vertical, Space.m)
        .onAppear {
            checkGoalJustMet()
        }
        .onChange(of: historyManager.todayState?.isGoalMet) { _ in
            checkGoalJustMet()
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Space.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.ppMicro)
                .foregroundColor(Theme.textTertiary)
        }
    }

    private func checkGoalJustMet() {
        guard historyManager.todayState?.isGoalMet == true else { return }
        let key = DailyGoalState.dayKey(for: Date())
        guard lastGoalPulseDay != key else { return }
        lastGoalPulseDay = key
        justMetGoal = true
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            justMetGoal = false
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
