import XCTest
@testable import PixelPal

final class PeriodTextTests: XCTestCase {

    func test_count_singularAndPlural() {
        XCTAssertEqual(PeriodText.count(1, .day), "1 day")
        XCTAssertEqual(PeriodText.count(2, .day), "2 days")
        XCTAssertEqual(PeriodText.count(1, .week), "1 week")
        XCTAssertEqual(PeriodText.count(3, .month), "3 months")
        XCTAssertEqual(PeriodText.count(1, .year), "1 year")
    }

    func test_count_zeroIsPlural() {
        XCTAssertEqual(PeriodText.count(0, .day), "0 days")
    }

    func test_count_groupsLargeNumbers() {
        XCTAssertEqual(PeriodText.count(1000, .day), 1000.formatted() + " days")
    }

    func test_perPeriod_dropsTheOne() {
        XCTAssertEqual(PeriodText.perPeriod(1, .year), "/year")
        XCTAssertEqual(PeriodText.perPeriod(1, .month), "/month")
        XCTAssertEqual(PeriodText.perPeriod(3, .month), "/3 months")
    }

    func test_spokenPerPeriod_readsNaturally() {
        XCTAssertEqual(PeriodText.spokenPerPeriod(1, .year), "per year")
        XCTAssertEqual(PeriodText.spokenPerPeriod(3, .month), "every 3 months")
    }

    func test_daysLeft() {
        XCTAssertEqual(PeriodText.daysLeft(0), "Ends today")
        XCTAssertEqual(PeriodText.daysLeft(1), "1 day left")
        XCTAssertEqual(PeriodText.daysLeft(6), "6 days left")
        XCTAssertEqual(PeriodText.daysLeft(-2), "Ends today")
    }

    func test_shortDaysLeft() {
        XCTAssertEqual(PeriodText.shortDaysLeft(0), "Ends today")
        XCTAssertEqual(PeriodText.shortDaysLeft(6), "6d left")
    }
}
