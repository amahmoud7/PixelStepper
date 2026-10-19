import XCTest
@testable import PixelPal

final class MissionProgressTests: XCTestCase {

    private func mission(_ type: MissionType, target: Int, progress: Int = 0) -> DailyMission {
        DailyMission(id: "m-\(type.rawValue)", type: type, title: "t", target: target,
                     progress: progress, coinReward: 10, dateString: "2026-10-19")
    }

    private func input(steps: Int, hour: Int, beforeNoon: Int? = nil, sinceFive: Int? = nil) -> MissionProgress.Input {
        MissionProgress.Input(todaySteps: steps, stepsBeforeNoon: beforeNoon, stepsSinceFivePM: sinceFive,
                              currentHour: hour, dailyGoal: 7500)
    }

    func test_eveningPush_usesOnlyStepsAfterFive() {
        // 5,000 steps during the day must not complete a "2,000 after 5pm" mission at 17:00.
        let m = mission(.eveningPush, target: 2000)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 5000, hour: 17, sinceFive: 0)), 0)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 6200, hour: 18, sinceFive: 1200)), 1200)
    }

    func test_eveningPush_beforeFive_noProgress() {
        let m = mission(.eveningPush, target: 2000)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 5000, hour: 16, sinceFive: nil)), 0)
    }

    func test_morningWalk_usesStepsBeforeNoon_evenWhenOpenedLater() {
        // Opening the app at 15:00 still credits the morning's steps.
        let m = mission(.morningWalk, target: 2000)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 4000, hour: 15, beforeNoon: 1500)), 1500)
        // Progress is capped at the target.
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 4000, hour: 15, beforeNoon: 2600)), 2000)
    }

    func test_morningWalk_withoutWindowData_afterNoon_keepsProgress() {
        let m = mission(.morningWalk, target: 1000, progress: 300)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 4000, hour: 15)), 300)
    }

    func test_progress_neverDecreases() {
        let m = mission(.stepTarget, target: 8000, progress: 5000)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 4000, hour: 10)), 5000)
    }

    func test_streakExtend_completesAtGoal() {
        let m = mission(.streakExtend, target: 1)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 7499, hour: 20)), 0)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 7500, hour: 20)), 1)
    }

    func test_consistentDay_noCreditBeforeMorning() {
        // At 1am a handful of steps used to count as a full "active hour".
        let m = mission(.consistentDay, target: 4)
        XCTAssertEqual(MissionProgress.evaluate(m, input(steps: 600, hour: 1)), 0)
    }
}
