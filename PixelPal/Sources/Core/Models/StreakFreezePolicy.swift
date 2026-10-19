import Foundation

/// Premium streak freeze: one missed day per 7 days is forgiven, if there's a streak to protect.
/// Pure, so reading the streak never has side effects; the caller records `freezeToRecord`.
enum StreakFreezePolicy {
    struct Result: Equatable {
        let streak: Int
        /// The missed day to persist as "freeze used", or nil if nothing new to record.
        let freezeToRecord: Date?
    }

    static func resolve(history: DailyHistory, lastFreezeDate: Date?, calendar: Calendar = .current) -> Result {
        let plain = Result(streak: history.countConsecutiveGoalsMet(), freezeToRecord: nil)
        let (frozenStreak, frozenDate) = history.countConsecutiveGoalsMetWithFreeze()
        guard let frozenDate else { return plain }

        // Only spend a freeze when a met day sits right before the miss.
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: frozenDate),
              history.state(for: dayBefore)?.isGoalMet == true else { return plain }

        if let lastFreezeDate {
            // Already recorded for this same miss: keep the protected streak.
            if calendar.isDate(lastFreezeDate, inSameDayAs: frozenDate) {
                return Result(streak: frozenStreak, freezeToRecord: nil)
            }
            let daysApart = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastFreezeDate),
                to: calendar.startOfDay(for: frozenDate)
            ).day ?? 0
            if abs(daysApart) < 7 { return plain }
        }
        return Result(streak: frozenStreak, freezeToRecord: frozenDate)
    }
}
