import SwiftUI

/// Compact streak row: flame + "N-day streak" + best, with this week's goal squares underneath.
/// Goal progress itself lives in the Home hero ring, so nothing here repeats it.
struct StreakHeroView: View {
    let streak: Int

    /// Observed so best streak and the week squares update live.
    @ObservedObject private var persistence = PersistenceManager.shared
    @ObservedObject private var historyManager = HistoryManager.shared

    private var bestStreak: Int {
        max(persistence.progressState.longestStreak, streak)
    }

    private var title: String {
        streak > 0 ? "\(streak)-day streak" : "Start a streak today"
    }

    var body: some View {
        let weekData = historyManager.history.weekViewData()
        let metCount = weekData.filter { $0.isGoalMet }.count

        VStack(alignment: .leading, spacing: Space.m) {
            HStack(spacing: Space.s) {
                Image(systemName: "flame.fill")
                    .font(.body)
                    .foregroundColor(streak > 0 ? Theme.amber : Theme.textTertiary)

                Text(title)
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: Space.s)

                if bestStreak > 0 {
                    Text("Best \(bestStreak)")
                        .font(.ppBody)
                        .foregroundColor(Theme.textSecondary)
                        .numericRoll(value: bestStreak)
                }
            }

            HStack(spacing: 0) {
                ForEach(weekData) { day in
                    WeekDaySquare(day: day)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .ppCard(padding: Space.l, radius: Radius.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(metCount: metCount, dayCount: weekData.count))
    }

    private func accessibilityText(metCount: Int, dayCount: Int) -> String {
        var parts = [title]
        if bestStreak > 0 { parts.append("best \(bestStreak) days") }
        parts.append("\(metCount) of \(dayCount) days at goal this week")
        return parts.joined(separator: ", ")
    }
}

/// One day of the week strip: a small rounded square plus its weekday initial.
private struct WeekDaySquare: View {
    let day: DailyHistory.DayViewData

    private var fill: Color {
        if day.isGoalMet { return Theme.goalMet }
        if day.hasData { return Theme.belowGoal }
        return Theme.noData
    }

    private var initial: String {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let index = calendar.component(.weekday, from: day.date) - 1
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    var body: some View {
        VStack(spacing: Space.xs) {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(fill)
                .frame(width: 10, height: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .stroke(day.isToday ? Theme.today : .clear, lineWidth: 1.5)
                        .padding(-2.5)
                )

            Text(initial)
                .font(.ppMicro)
                .foregroundColor(day.isToday ? Theme.textPrimary : Theme.textTertiary)
        }
    }
}
