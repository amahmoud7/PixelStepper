import XCTest
@testable import PixelPal

final class StreakFreezePolicyTests: XCTestCase {

    private let calendar = Calendar.current

    /// Goal met on each of `metOffsets` (days relative to today, e.g. -2).
    private func history(met metOffsets: [Int]) -> DailyHistory {
        var history = DailyHistory.createNew()
        let today = calendar.startOfDay(for: Date())
        for offset in metOffsets {
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            history.recordDay(DailyGoalState.create(for: date, steps: 8000, goal: 7500))
        }
        return history
    }

    private var yesterday: Date {
        calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
    }

    func test_missYesterdayAfterStreak_freezesAndRecords() {
        let h = history(met: Array(-10 ... -2))   // 9 met days, yesterday missed
        let result = StreakFreezePolicy.resolve(history: h, lastFreezeDate: nil)
        XCTAssertEqual(result.streak, 10)        // 9 met + the frozen day
        XCTAssertTrue(calendar.isDate(result.freezeToRecord!, inSameDayAs: yesterday))
    }

    func test_secondEvaluationAfterRecording_keepsFrozenStreak() {
        // Regression: the freeze used to undo itself on the next read.
        let h = history(met: Array(-10 ... -2))
        let result = StreakFreezePolicy.resolve(history: h, lastFreezeDate: yesterday)
        XCTAssertEqual(result.streak, 10)
        XCTAssertNil(result.freezeToRecord)
    }

    func test_emptyHistory_doesNotSpendFreeze() {
        let result = StreakFreezePolicy.resolve(history: DailyHistory.createNew(), lastFreezeDate: nil)
        XCTAssertEqual(result.streak, 0)
        XCTAssertNil(result.freezeToRecord)
    }

    func test_freezeUsedWithinAWeek_isNotAvailable() {
        let h = history(met: Array(-10 ... -2))
        let threeDaysBefore = calendar.date(byAdding: .day, value: -3, to: yesterday)!
        let result = StreakFreezePolicy.resolve(history: h, lastFreezeDate: threeDaysBefore)
        XCTAssertEqual(result.streak, 0)
        XCTAssertNil(result.freezeToRecord)
    }

    func test_noMiss_returnsPlainStreak() {
        let h = history(met: Array(-5 ... -1))
        let result = StreakFreezePolicy.resolve(history: h, lastFreezeDate: nil)
        XCTAssertEqual(result.streak, 5)
        XCTAssertNil(result.freezeToRecord)
    }
}
