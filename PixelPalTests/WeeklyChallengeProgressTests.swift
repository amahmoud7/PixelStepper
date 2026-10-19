import XCTest
@testable import PixelPal

final class WeeklyChallengeProgressTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = hour
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    private func day(_ date: Date, _ steps: Int) -> WeeklyChallengeProgress.DayTotal {
        .init(date: date, steps: steps, goalMet: steps >= 7500)
    }

    func test_weekKey_usesISOWeeks_acrossYearBoundary() {
        XCTAssertEqual(WeeklyChallengeProgress.weekKey(for: date(2025, 12, 29)), "2026-W01")
        XCTAssertEqual(WeeklyChallengeProgress.weekKey(for: date(2026, 10, 19)), "2026-W43")
    }

    func test_onlyDaysInTheCurrentWeekCount() {
        // Monday 2026-10-19: last Sunday's steps must not count toward this week.
        let monday = date(2026, 10, 19)
        let days = [day(date(2026, 10, 18), 20_000), day(monday, 3_000)]
        XCTAssertEqual(WeeklyChallengeProgress.progress(for: .totalSteps, days: days, now: monday), 3_000)
        XCTAssertEqual(WeeklyChallengeProgress.progress(for: .bigDay, days: days, now: monday), 0)
    }

    func test_consistentWeek_counts5kDays_notGoalDays() {
        let monday = date(2026, 10, 19)
        let days = [day(monday, 5_200), day(date(2026, 10, 20), 4_900), day(date(2026, 10, 21), 9_000)]
        let wednesday = date(2026, 10, 21)
        XCTAssertEqual(WeeklyChallengeProgress.progress(for: .consistentWeek, days: days, now: wednesday), 2)
        XCTAssertEqual(WeeklyChallengeProgress.progress(for: .activeDays, days: days, now: wednesday), 1)
    }

    func test_bigDay_completesAt10k() {
        let now = date(2026, 10, 22)
        XCTAssertEqual(WeeklyChallengeProgress.progress(for: .bigDay, days: [day(now, 10_000)], now: now), 1)
    }
}
