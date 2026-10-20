import Foundation

/// Calendar units the app counts in (subscription periods, trials, streak days).
enum PeriodUnit {
    case day, week, month, year

    fileprivate var singular: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }
}

/// Pluralized period strings, so no screen hand-rolls "s" suffixes ("best 1 days").
enum PeriodText {
    /// "1 day", "3 months".
    static func count(_ value: Int, _ unit: PeriodUnit) -> String {
        "\(value.formatted()) \(value == 1 ? unit.singular : unit.singular + "s")"
    }

    /// Price suffix: "/year", "/3 months".
    static func perPeriod(_ value: Int, _ unit: PeriodUnit) -> String {
        value == 1 ? "/\(unit.singular)" : "/\(count(value, unit))"
    }

    /// VoiceOver reads "/year" as "slash year"; this is the spoken form.
    static func spokenPerPeriod(_ value: Int, _ unit: PeriodUnit) -> String {
        value == 1 ? "per \(unit.singular)" : "every \(count(value, unit))"
    }

    /// "Ends today", "1 day left", "6 days left".
    static func daysLeft(_ days: Int) -> String {
        days <= 0 ? "Ends today" : "\(count(days, .day)) left"
    }

    /// Compact visual form of `daysLeft`: "6d left".
    static func shortDaysLeft(_ days: Int) -> String {
        days <= 0 ? "Ends today" : "\(days)d left"
    }
}
