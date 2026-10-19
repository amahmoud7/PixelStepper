import XCTest
@testable import PixelPal

final class RewardLedgerTests: XCTestCase {

    private let goal = 7500

    // MARK: - Daily goal

    func test_claimDailyGoal_belowGoal_returnsFalse() {
        var ledger = RewardLedger()
        XCTAssertFalse(ledger.claimDailyGoal(todaySteps: 7499, goal: goal, day: "2026-10-15"))
    }

    func test_claimDailyGoal_secondRefreshSameDay_paysOnce() {
        var ledger = RewardLedger()
        XCTAssertTrue(ledger.claimDailyGoal(todaySteps: 8000, goal: goal, day: "2026-10-15"))
        XCTAssertFalse(ledger.claimDailyGoal(todaySteps: 9000, goal: goal, day: "2026-10-15"))
    }

    func test_claimDailyGoal_nextDay_paysAgain() {
        var ledger = RewardLedger()
        _ = ledger.claimDailyGoal(todaySteps: 8000, goal: goal, day: "2026-10-15")
        XCTAssertTrue(ledger.claimDailyGoal(todaySteps: 8000, goal: goal, day: "2026-10-16"))
    }

    // MARK: - Streak milestones

    func test_claimStreakMilestone_nonMilestone_returnsNil() {
        var ledger = RewardLedger()
        XCTAssertNil(ledger.claimStreakMilestone(streak: 8, todaySteps: 8000, goal: goal, day: "2026-10-15"))
    }

    func test_claimStreakMilestone_goalNotMetToday_returnsNil() {
        // Streak still reads 7 the morning after reaching it; must not pay again.
        var ledger = RewardLedger()
        XCTAssertNil(ledger.claimStreakMilestone(streak: 7, todaySteps: 100, goal: goal, day: "2026-10-16"))
    }

    func test_claimStreakMilestone_paysOncePerDay_withTieredReward() {
        var ledger = RewardLedger()
        XCTAssertEqual(ledger.claimStreakMilestone(streak: 7, todaySteps: 8000, goal: goal, day: "d1"), 100)
        XCTAssertNil(ledger.claimStreakMilestone(streak: 7, todaySteps: 9000, goal: goal, day: "d1"))
        var fresh = RewardLedger()
        XCTAssertEqual(fresh.claimStreakMilestone(streak: 30, todaySteps: 8000, goal: goal, day: "d1"), 300)
        XCTAssertEqual(fresh.claimStreakMilestone(streak: 100, todaySteps: 8000, goal: goal, day: "d2"), 500)
    }

    // MARK: - Personal record

    func test_claimPersonalRecord_paysOncePerDay() {
        var ledger = RewardLedger()
        XCTAssertTrue(ledger.claimPersonalRecord(todaySteps: 12000, previousBest: 10000, day: "d1"))
        XCTAssertFalse(ledger.claimPersonalRecord(todaySteps: 13000, previousBest: 12000, day: "d1"))
    }

    func test_claimPersonalRecord_tinyDays_ignored() {
        var ledger = RewardLedger()
        XCTAssertFalse(ledger.claimPersonalRecord(todaySteps: 900, previousBest: 0, day: "d1"))
    }

    // MARK: - Step milestones

    func test_claimStepMilestone_paysEachMilestoneOnce() {
        var ledger = RewardLedger()
        XCTAssertTrue(ledger.claimStepMilestone(50_000))
        XCTAssertFalse(ledger.claimStepMilestone(50_000))
        XCTAssertFalse(ledger.claimStepMilestone(25_000))
        XCTAssertTrue(ledger.claimStepMilestone(100_000))
    }

    // MARK: - Coins

    func test_addingCoins_saturatesInsteadOfOverflowing() {
        XCTAssertEqual(RewardLedger.adding(10, to: Int.max - 5), Int.max)
        XCTAssertEqual(RewardLedger.adding(10, to: 5), 15)
    }

    // MARK: - Persistence

    func test_progressState_decodesLegacyJSONWithoutLedger() throws {
        let legacy = #"{"totalStepsSinceStart":100,"currentPhase":1,"hasSeenPaywall":false,"todaySteps":10}"#
        let state = try JSONDecoder().decode(ProgressState.self, from: Data(legacy.utf8))
        XCTAssertEqual(state.rewardLedger, RewardLedger())
    }

    func test_progressState_roundTripsLedger() throws {
        var state = ProgressState.createNew()
        _ = state.rewardLedger.claimDailyGoal(todaySteps: 8000, goal: goal, day: "d1")
        _ = state.rewardLedger.claimStepMilestone(50_000)
        let decoded = try JSONDecoder().decode(ProgressState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(decoded.rewardLedger, state.rewardLedger)
    }
}
