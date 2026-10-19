import SwiftUI

/// 30-day heatmap grid using DailyHistory data (goal met / below goal / no data squares).
struct MonthCalendarView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        let days = calendarDays

        VStack(spacing: Space.m) {
            HStack {
                Text("30-day activity")
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                legendDots
            }

            // Day-of-week headers
            HStack(spacing: 4) {
                ForEach(Array(Calendar.current.veryShortStandaloneWeekdaySymbols.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.ppMicro)
                        .foregroundColor(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                // Leading spacer cells to align with weekday
                ForEach(0..<leadingSpacers(for: days), id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityHidden(true)
                }

                ForEach(days, id: \.dateString) { day in
                    calendarCell(for: day)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Data

    private var calendarDays: [CalendarDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var days: [CalendarDay] = []

        for offset in stride(from: -29, through: 0, by: 1) {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let state = historyManager.history.state(for: date)
            let isToday = offset == 0

            days.append(CalendarDay(
                date: date,
                dateString: DailyGoalState.dayKey(for: date),
                dayNumber: calendar.component(.day, from: date),
                steps: state?.steps ?? 0,
                goalMet: state?.isGoalMet ?? false,
                hasData: state != nil && (state?.steps ?? 0) > 0,
                isToday: isToday
            ))
        }

        return days
    }

    private func leadingSpacers(for days: [CalendarDay]) -> Int {
        guard let firstDay = days.first else { return 0 }
        // Headers start on Sunday (weekday 1), matching the symbol order above.
        let weekday = Calendar.current.component(.weekday, from: firstDay.date)
        return weekday - 1
    }

    // MARK: - Cell

    @ViewBuilder
    private func calendarCell(for day: CalendarDay) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cellColor(for: day))

            if day.isToday {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Theme.textSecondary, lineWidth: 1.5)
            }

            // Fixed size: cells are small squares sized by the grid, not by text.
            Text("\(day.dayNumber)")
                .font(.system(size: 11, weight: day.isToday ? .bold : .medium))
                .foregroundColor(day.hasData || day.isToday ? Theme.textPrimary : Theme.textTertiary)
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            // Met vs below goal must not rely on color alone.
            if differentiateWithoutColor && day.goalMet {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: day))
    }

    private func accessibilityLabel(for day: CalendarDay) -> String {
        let date = day.date.formatted(date: .abbreviated, time: .omitted)
        let prefix = day.isToday ? "Today, \(date)" : date
        return "\(prefix), \(day.steps.formatted()) steps\(day.goalMet ? ", goal met" : "")"
    }

    private func cellColor(for day: CalendarDay) -> Color {
        guard day.hasData || day.isToday else {
            return Theme.noData
        }

        if day.goalMet {
            return Theme.goalMet.opacity(day.isToday ? 0.8 : 0.6)
        } else if day.steps > 0 {
            return Theme.belowGoal
        }

        return Theme.noData
    }

    // MARK: - Legend

    private var legendDots: some View {
        HStack(spacing: Space.s) {
            legendItem(color: Theme.goalMet, label: "Met")
            legendItem(color: Theme.belowGoal, label: "Below goal")
        }
        .accessibilityElement(children: .combine)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.ppMicro)
                .foregroundColor(Theme.textTertiary)
        }
    }
}

// MARK: - Model

private struct CalendarDay {
    let date: Date
    let dateString: String
    let dayNumber: Int
    let steps: Int
    let goalMet: Bool
    let hasData: Bool
    let isToday: Bool
}
