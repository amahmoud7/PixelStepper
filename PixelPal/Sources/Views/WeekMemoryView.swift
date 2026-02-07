import SwiftUI

/// 7-Day Memory UI component (v1.1).
/// Shows rolling 7-day window with 6 past days + today indicator.
///
/// Design:
/// - 24pt circles with 12pt spacing
/// - Green (#34C759) = met goal
/// - Red 70% opacity = missed goal  
/// - Blue pulse = today
/// - 0.3s fill animation on state change
struct WeekMemoryView: View {
    /// Day view data from HistoryManager.
    let days: [DailyHistory.DayViewData]

    /// Whether today's goal was just met (triggers pulse animation).
    let justMetGoal: Bool

    /// Animation state for fills.
    @State private var animatedDays: [Bool] = []

    /// Pulse animation state for today.
    @State private var isPulsing: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                DayBubble(
                    day: day,
                    isPulsing: day.isToday && (justMetGoal || isPulsing)
                )
                .scaleEffect(animatedDays.indices.contains(index) && animatedDays[index] ? 1.0 : 0.1)
                .opacity(animatedDays.indices.contains(index) && animatedDays[index] ? 1.0 : 0.0)
                .animation(
                    .easeOut(duration: 0.3).delay(Double(index) * 0.05),
                    value: animatedDays
                )
            }
        }
        .onAppear {
            // Initialize animation states
            animatedDays = Array(repeating: false, count: days.count)

            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animatedDays = Array(repeating: true, count: days.count)
                }
            }

            // Start pulse for today
            startPulseIfToday()
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

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)
                .frame(width: bubbleSize, height: bubbleSize)

            // Pulse overlay for today
            if day.isToday && isPulsing {
                Circle()
                    .stroke(bubbleColor, lineWidth: 2)
                    .frame(width: bubbleSize + 8, height: bubbleSize + 8)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(
                        .easeInOut(duration: 0.6).repeatCount(3, autoreverses: true),
                        value: isPulsing
                    )
            }

            // Inner indicator dot for today
            if day.isToday {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
            }

            // Checkmark for goal met (past days)
            if !day.isToday && day.isGoalMet && day.hasData {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .overlay(
            // Tooltip on hover/press (conceptual - could be expanded)
            dayTooltip
        )
    }

    @ViewBuilder
    private var dayTooltip: some View {
        // Empty for now - could add hover tooltip in future
        EmptyView()
    }

    private var backgroundColor: Color {
        if day.isToday {
            // Today uses blue tint with goal status fill
            if day.isGoalMet {
                return Color(hex: "#34C759") // Green
            } else {
                return Color.blue.opacity(0.3)
            }
        } else {
            // Past days
            if !day.hasData {
                // No data yet (future or missing)
                return Color.gray.opacity(0.15)
            } else if day.isGoalMet {
                return Color(hex: "#34C759") // Green for met
            } else {
                return Color(hex: "#FF3B30").opacity(0.7) // Red 70% for missed
            }
        }
    }

    private var bubbleColor: Color {
        if day.isGoalMet {
            return Color(hex: "#34C759")
        } else {
            return Color.blue
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
            return day.isGoalMet ? Color(hex: "#34C759") : Color.blue
        } else if !day.hasData {
            return Color.gray.opacity(0.3)
        } else if day.isGoalMet {
            return Color(hex: "#34C759")
        } else {
            return Color(hex: "#FF3B30").opacity(0.7)
        }
    }
}

// MARK: - Week Memory Section

/// Full section view for ContentView with label.
struct WeekMemorySection: View {
    @StateObject private var historyManager = HistoryManager.shared
    @State private var justMetGoal: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Week bubbles
            WeekMemoryView(
                days: historyManager.last7Days(),
                justMetGoal: justMetGoal
            )

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#34C759"))
                        .frame(width: 8, height: 8)
                    Text("Met")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#FF3B30").opacity(0.7))
                        .frame(width: 8, height: 8)
                    Text("Missed")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 12)
        .onAppear {
            checkGoalJustMet()
        }
        .onChange(of: historyManager.todayState?.isGoalMet) { _ in
            checkGoalJustMet()
        }
    }

    private func checkGoalJustMet() {
        if historyManager.todayState?.isGoalMet == true {
            justMetGoal = true
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                justMetGoal = false
            }
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
