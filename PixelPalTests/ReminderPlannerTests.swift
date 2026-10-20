import XCTest
@testable import PixelPal

final class ReminderPlannerTests: XCTestCase {

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    /// Wednesday 2026-10-14 at the given hour.
    private func wednesday(hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: hour))!
    }

    private func plan(now: Date, goalMet: Bool = false, streak: Int = 0) -> [PlannedReminder] {
        ReminderPlanner.plan(now: now, goalMetToday: goalMet, streak: streak, calendar: calendar)
    }

    private func reminders(on day: Date, in plan: [PlannedReminder]) -> [PlannedReminder] {
        plan.filter { calendar.isDate($0.fireDate, inSameDayAs: day) }
    }

    func test_neverMoreThanTwoPerDay() {
        let result = plan(now: wednesday(hour: 7))
        for offset in 0..<ReminderPlanner.daysAhead {
            let day = calendar.date(byAdding: .day, value: offset, to: wednesday(hour: 12))!
            XCTAssertLessThanOrEqual(reminders(on: day, in: result).count, 2)
        }
    }

    func test_coversAWeek_andStaysUnderSystemLimit() {
        let result = plan(now: wednesday(hour: 7))
        XCTAssertEqual(result.count, ReminderPlanner.daysAhead * 2)
        XCTAssertLessThan(result.count, 64, "iOS keeps at most 64 pending notifications")
    }

    func test_nothingInThePast() {
        let now = wednesday(hour: 20)
        XCTAssertTrue(plan(now: now).allSatisfy { $0.fireDate > now })
        XCTAssertTrue(reminders(on: now, in: plan(now: now)).isEmpty)
    }

    func test_goalMetToday_skipsTodaysReminders_butKeepsTomorrow() {
        let now = wednesday(hour: 7)
        let result = plan(now: now, goalMet: true)
        XCTAssertTrue(reminders(on: now, in: result).isEmpty)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        XCTAssertEqual(reminders(on: tomorrow, in: result).count, 2)
    }

    func test_streakAtRisk_usesStreakCopyTonightOnly() {
        let now = wednesday(hour: 12)
        let result = plan(now: now, streak: 12)
        let tonight = reminders(on: now, in: result)
        XCTAssertEqual(tonight.count, 1)
        XCTAssertTrue(tonight[0].title.contains("12-day streak"), tonight[0].title)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        XCTAssertFalse(reminders(on: tomorrow, in: result).contains { $0.title.contains("streak") },
                       "Future days can't know the streak; no stale numbers")
    }

    func test_sundayEvening_isWeeklySummary() {
        let result = plan(now: wednesday(hour: 7))
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 12))!
        let evening = reminders(on: sunday, in: result).filter { calendar.component(.hour, from: $0.fireDate) == ReminderPlanner.eveningHour }
        XCTAssertEqual(evening.count, 1)
        XCTAssertTrue(evening[0].title.lowercased().contains("week"), evening[0].title)
    }

    func test_identifiersAreUniqueAndPrefixed() {
        let ids = plan(now: wednesday(hour: 7)).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertTrue(ids.allSatisfy { $0.hasPrefix(ReminderPlanner.idPrefix) })
    }

    func test_noStepCountsOnTheLockScreen() {
        let result = plan(now: wednesday(hour: 7), streak: 5)
        XCTAssertFalse(result.contains { ($0.title + $0.body).contains(where: \.isNumber) && !$0.title.contains("5-day") })
    }
}
