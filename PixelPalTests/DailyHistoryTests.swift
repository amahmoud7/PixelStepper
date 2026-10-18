import XCTest
@testable import PixelPal

final class DailyHistoryTests: XCTestCase {

    private func history(goalMetDays: Int, includeToday: Bool = false) -> DailyHistory {
        var history = DailyHistory.createNew()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = includeToday ? 0 : 1
        for offset in start...goalMetDays where goalMetDays > 0 {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            history.recordDay(DailyGoalState.create(for: date, steps: 8000, goal: 7500))
        }
        return history
    }

    func test_countConsecutiveGoalsMet_beyond30Days_isNotCapped() {
        // 60/100-day streak milestones and the 100-day cosmetic must be reachable.
        let streak = history(goalMetDays: 120).countConsecutiveGoalsMet()
        XCTAssertEqual(streak, 120)
    }

    func test_recordDay_keepsMoreThanAYear() {
        let h = history(goalMetDays: 380)
        XCTAssertEqual(h.days.count, 380)
    }

    func test_stateForDate_findsRecordedDay() {
        let h = history(goalMetDays: 3)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(h.state(for: yesterday)?.steps, 8000)
    }

    func test_dayKey_matchesStoredFormat() {
        var components = DateComponents()
        components.year = 2026; components.month = 3; components.day = 7; components.hour = 12
        let date = Calendar.current.date(from: components)!
        XCTAssertEqual(DailyGoalState.dayKey(for: date), "2026-03-07")
        XCTAssertEqual(DailyGoalState.create(for: date).dateString, "2026-03-07")
    }

    func test_seededGenerator_sameString_sameSequence() {
        var a = SeededRandomNumberGenerator(string: "2026-10-15")
        var b = SeededRandomNumberGenerator(string: "2026-10-15")
        XCTAssertEqual(a.next(), b.next())
        XCTAssertEqual(a.next(), b.next())
    }

    func test_seededGenerator_differentStrings_differ() {
        var a = SeededRandomNumberGenerator(string: "2026-10-15")
        var b = SeededRandomNumberGenerator(string: "2026-10-16")
        XCTAssertNotEqual(a.next(), b.next())
    }
}
