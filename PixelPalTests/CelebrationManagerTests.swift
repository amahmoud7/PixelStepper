import XCTest
@testable import PixelPal

@MainActor
final class CelebrationManagerTests: XCTestCase {

    func test_dequeueNext_returnsQueuedEventsInOrder() {
        let manager = CelebrationManager()
        manager.tryTrigger(.dailyGoalMet(steps: 8000))
        manager.tryTrigger(.streakMilestone(days: 7))

        XCTAssertEqual(manager.dequeueNext(), .dailyGoalMet(steps: 8000))
        // Several celebrations earned in one update must all be shown, one after another.
        XCTAssertEqual(manager.dequeueNext(), .streakMilestone(days: 7))
        XCTAssertNil(manager.dequeueNext())
    }

    func test_tryTrigger_sameEventTwice_isShownOnce() {
        let manager = CelebrationManager()
        XCTAssertTrue(manager.tryTrigger(.streakMilestone(days: 7)))
        XCTAssertFalse(manager.tryTrigger(.streakMilestone(days: 7)))
        _ = manager.dequeueNext()
        XCTAssertFalse(manager.tryTrigger(.streakMilestone(days: 7)), "already shown")
    }
}
