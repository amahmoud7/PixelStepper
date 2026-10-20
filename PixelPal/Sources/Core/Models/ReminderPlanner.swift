import Foundation

/// One local notification to schedule.
struct PlannedReminder: Equatable {
    let id: String
    let fireDate: Date
    let title: String
    let body: String
}

/// Decides which reminders to send over the next week: at most a morning and an evening one per day,
/// nothing for a day whose goal is already met, and streak copy only for tonight (future streaks are unknown).
/// One-shot dates instead of repeating triggers, so a met goal can actually cancel the evening nudge.
enum ReminderPlanner {
    static let morningHour = 9
    static let eveningHour = 19
    /// 7 days × 2 stays far below the 64 pending-notification cap and stops nudging lapsed users after a week.
    static let daysAhead = 7
    static let idPrefix = "pp_reminder_"

    static func plan(now: Date, goalMetToday: Bool, streak: Int, calendar: Calendar = .current) -> [PlannedReminder] {
        let today = calendar.startOfDay(for: now)
        var result: [PlannedReminder] = []

        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let isToday = offset == 0
            if isToday && goalMetToday { continue }

            if let morning = calendar.date(bySettingHour: morningHour, minute: 0, second: 0, of: day), morning > now {
                result.append(PlannedReminder(
                    id: id("morning", day, calendar),
                    fireDate: morning,
                    title: "Your Stepper is waiting",
                    body: "A morning walk gets your character moving today."
                ))
            }

            if let evening = calendar.date(bySettingHour: eveningHour, minute: 0, second: 0, of: day), evening > now {
                let isSunday = calendar.component(.weekday, from: day) == 1
                let copy: (title: String, body: String)
                if isToday && streak > 0 {
                    copy = ("Keep your \(streak)-day streak going", "A short walk this evening keeps it alive.")
                } else if isSunday {
                    copy = ("Your week in review", "See how your Stepper did this week.")
                } else {
                    copy = ("Still time to hit your goal", "A short walk can push your Stepper to vital.")
                }
                result.append(PlannedReminder(id: id("evening", day, calendar), fireDate: evening, title: copy.title, body: copy.body))
            }
        }
        return result
    }

    private static func id(_ slot: String, _ day: Date, _ calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return "\(idPrefix)\(slot)_\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
