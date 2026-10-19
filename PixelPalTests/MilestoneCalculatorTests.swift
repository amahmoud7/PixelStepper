import XCTest
@testable import PixelPal

final class MilestoneCalculatorTests: XCTestCase {

    func test_checkMilestone_crossingTwo_returnsHighest() {
        // Otherwise the higher milestone is never paid (the ledger only pays increasing milestones).
        XCTAssertEqual(MilestoneCalculator.checkMilestone(previousSteps: 4_000, currentSteps: 8_000), 7_500)
    }

    func test_checkMilestone_exactBoundary() {
        XCTAssertEqual(MilestoneCalculator.checkMilestone(previousSteps: 4_999, currentSteps: 5_000), 5_000)
        XCTAssertNil(MilestoneCalculator.checkMilestone(previousSteps: 5_000, currentSteps: 5_001))
    }

    func test_formatMilestone_keepsFractions() {
        let format = MilestoneCalculator.formatMilestone
        XCTAssertNotEqual(format(2_500), format(2_000), "2,500 must not render as 2k")
        XCTAssertNotEqual(format(7_500), format(7_000), "7,500 must not render as 7k")
        XCTAssertTrue(format(100_000).hasSuffix("!"))
    }

    func test_shortMilestone_hasNoExclamation() {
        XCTAssertFalse(MilestoneCalculator.shortMilestone(100_000).contains("!"))
        XCTAssertEqual(MilestoneCalculator.formatMilestone(100_000), MilestoneCalculator.shortMilestone(100_000) + "!")
    }

    func test_stepMilestoneTitle_singleExclamation() {
        let title = CelebrationEvent.stepMilestone(cumulative: 100_000).title
        XCTAssertEqual(title.filter { $0 == "!" }.count, 1, title)
    }

    func test_stepMilestoneSpokenTitle_spellsOutNumber() {
        let spoken = CelebrationEvent.stepMilestone(cumulative: 100_000).spokenTitle
        XCTAssertTrue(spoken.contains(100_000.formatted()), spoken)
        XCTAssertEqual(CelebrationEvent.dailyGoalMet(steps: 8000).spokenTitle, CelebrationEvent.dailyGoalMet(steps: 8000).title)
    }
}
