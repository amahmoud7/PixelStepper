import SwiftUI

/// Second page: streak, best streak, this week's goal squares and the current phase.
struct StreakView: View {
    @EnvironmentObject private var store: WatchStore

    private var streak: Int { store.snapshot.currentStreak }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak > 0 ? WatchPalette.amber : .secondary)
                    .accessibilityHidden(true)
                Text(streak > 0 ? "\(streak)-day streak" : "Start a streak")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if store.snapshot.longestStreak > 0 {
                Text("Best \(store.snapshot.longestStreak)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            weekSquares

            Text("\(store.week.filter { $0.steps >= store.snapshot.dailyGoal }.count) of 7 days at goal")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)   // the squares already announce this

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Circle()
                    .fill(WatchPalette.phaseColor(store.snapshot.phase))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("Phase \(store.snapshot.phase) · \(WatchPalette.phaseName(store.snapshot.phase))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var weekSquares: some View {
        let goal = store.snapshot.dailyGoal
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(store.week) { day in
                let isToday = calendar.isDateInToday(day.date)
                let met = day.steps >= goal
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(met ? WatchPalette.mint : (isToday || day.steps == 0 ? WatchPalette.noData : WatchPalette.belowGoal))
                        .frame(width: 12, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(isToday ? WatchPalette.blue : .clear, lineWidth: 1.5)
                                .padding(-2)
                        )
                    Text(symbols[(calendar.component(.weekday, from: day.date) - 1) % symbols.count])
                        .font(.system(size: 10))
                        .foregroundStyle(isToday ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(store.week.filter { $0.steps >= goal }.count) of 7 days at goal this week")
    }
}
