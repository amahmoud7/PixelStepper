import XCTest
@testable import PixelPal

final class WatchSnapshotTests: XCTestCase {

    private let sample = WatchSnapshot(
        gender: .female,
        phase: 3,
        currentStreak: 12,
        longestStreak: 21,
        dailyGoal: 7500,
        updatedAt: Date(timeIntervalSince1970: 1_760_000_000)
    )

    func test_dictionary_roundTrips() {
        XCTAssertEqual(WatchSnapshot(dictionary: sample.dictionary), sample)
    }

    func test_dictionary_isPropertyListSafe() {
        // WatchConnectivity application contexts only accept property-list types.
        XCTAssertTrue(PropertyListSerialization.propertyList(sample.dictionary, isValidFor: .binary))
    }

    func test_unknownGender_isRejected() {
        var dict = sample.dictionary
        dict["gender"] = "robot"
        XCTAssertNil(WatchSnapshot(dictionary: dict))
    }

    func test_missingKeys_areRejected() {
        XCTAssertNil(WatchSnapshot(dictionary: [:]))
    }

    func test_phase_isClampedToValidRange() {
        var dict = sample.dictionary
        dict["phase"] = 9
        XCTAssertEqual(WatchSnapshot(dictionary: dict)?.phase, 4)
    }

    func test_goalProgress_isClamped() {
        XCTAssertEqual(sample.goalProgress(steps: 3_750), 0.5, accuracy: 0.0001)
        XCTAssertEqual(sample.goalProgress(steps: 20_000), 1)
        XCTAssertEqual(sample.goalProgress(steps: -5), 0)
    }
}
