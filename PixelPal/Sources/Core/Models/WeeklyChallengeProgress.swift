import Foundation

/// Pure weekly-challenge rules on ISO-8601 weeks (Monday start), independent of the user's locale.
enum WeeklyChallengeProgress {
    struct DayTotal {
        let date: Date
        let steps: Int
        let goalMet: Bool
    }

    static let consistentDaySteps = 5_000
    static let bigDaySteps = 10_000

    private static var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }

    /// e.g. "2026-W43". Stable across locales; used to key the saved challenge.
    static func weekKey(for date: Date) -> String {
        let calendar = isoCalendar
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return "\(year)-W" + (week < 10 ? "0\(week)" : "\(week)")
    }

    /// Progress toward `type` using only days in the ISO week containing `now`.
    static func progress(for type: WeeklyChallengeType, days: [DayTotal], now: Date = Date()) -> Int {
        guard let week = isoCalendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        let thisWeek = days.filter { week.contains($0.date) }
        switch type {
        case .totalSteps:
            return thisWeek.reduce(0) { $0 + $1.steps }
        case .activeDays, .streakWeek:
            return thisWeek.filter(\.goalMet).count
        case .consistentWeek:
            return thisWeek.filter { $0.steps >= consistentDaySteps }.count
        case .bigDay:
            return thisWeek.contains { $0.steps >= bigDaySteps } ? 1 : 0
        }
    }
}
