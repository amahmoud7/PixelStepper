import XCTest
@testable import PixelPal

final class SpriteAssetsTests: XCTestCase {

    // MARK: - State Sprite Name Generation

    func testSpriteName_maleVital1() {
        let name = SpriteAssets.spriteName(gender: .male, state: .vital, frame: 1)
        XCTAssertEqual(name, "male_vital_1")
    }

    func testSpriteName_maleVital2() {
        let name = SpriteAssets.spriteName(gender: .male, state: .vital, frame: 2)
        XCTAssertEqual(name, "male_vital_2")
    }

    func testSpriteName_femaleNeutral1() {
        let name = SpriteAssets.spriteName(gender: .female, state: .neutral, frame: 1)
        XCTAssertEqual(name, "female_neutral_1")
    }

    func testSpriteName_femaleNeutral2() {
        let name = SpriteAssets.spriteName(gender: .female, state: .neutral, frame: 2)
        XCTAssertEqual(name, "female_neutral_2")
    }

    func testSpriteName_maleLow1() {
        let name = SpriteAssets.spriteName(gender: .male, state: .low, frame: 1)
        XCTAssertEqual(name, "male_low_1")
    }

    func testSpriteName_femaleLow2() {
        let name = SpriteAssets.spriteName(gender: .female, state: .low, frame: 2)
        XCTAssertEqual(name, "female_low_2")
    }

    // MARK: - All State Sprite Combinations

    func testSpriteName_allStateCombinations() {
        for gender in Gender.allCases {
            for state in [AvatarState.low, .neutral, .vital] {
                for frame in 1...2 {
                    let name = SpriteAssets.spriteName(gender: gender, state: state, frame: frame)
                    XCTAssertEqual(name, "\(gender.rawValue)_\(state.rawValue)_\(frame)")
                    XCTAssertFalse(name.isEmpty)
                }
            }
        }
    }

    // MARK: - Raw String Overload

    func testSpriteNameRaw_validStrings() {
        let name = SpriteAssets.spriteName(genderRaw: "female", stateRaw: "vital", frame: 2)
        XCTAssertEqual(name, "female_vital_2")
    }

    func testSpriteNameRaw_maleNeutral() {
        let name = SpriteAssets.spriteName(genderRaw: "male", stateRaw: "neutral", frame: 1)
        XCTAssertEqual(name, "male_neutral_1")
    }

    // MARK: - Walking Sprites

    func testWalkingSpriteName_maleFrame1() {
        let name = SpriteAssets.walkingSpriteName(gender: .male, frame: 1)
        XCTAssertEqual(name, "male_walking_1")
    }

    func testWalkingSpriteName_femaleFrame8() {
        let name = SpriteAssets.walkingSpriteName(gender: .female, frame: 8)
        XCTAssertEqual(name, "female_walking_8")
    }

    func testWalkingSpriteName_midFrame() {
        let name = SpriteAssets.walkingSpriteName(gender: .male, frame: 5)
        XCTAssertEqual(name, "male_walking_5")
    }

    // MARK: - Walking Frame Clamping

    func testWalkingSpriteName_clampsToOne_whenZero() {
        let name = SpriteAssets.walkingSpriteName(gender: .female, frame: 0)
        XCTAssertEqual(name, "female_walking_1")
    }

    func testWalkingSpriteName_clampsToOne_whenNegative() {
        let name = SpriteAssets.walkingSpriteName(gender: .male, frame: -5)
        XCTAssertEqual(name, "male_walking_1")
    }

    func testWalkingSpriteName_clampsToLastFrame_whenOnePastEnd() {
        let name = SpriteAssets.walkingSpriteName(gender: .male, frame: SpriteAssets.walkingFrameCount + 1)
        XCTAssertEqual(name, "male_walking_\(SpriteAssets.walkingFrameCount)")
    }

    func testWalkingSpriteName_clampsToLastFrame_whenLarge() {
        let name = SpriteAssets.walkingSpriteName(gender: .female, frame: 100)
        XCTAssertEqual(name, "female_walking_\(SpriteAssets.walkingFrameCount)")
    }

    // MARK: - Walking Raw String Overload

    func testWalkingSpriteName_rawMale() {
        let name = SpriteAssets.walkingSpriteName(genderRaw: "male", frame: 3)
        XCTAssertEqual(name, "male_walking_3")
    }

    func testWalkingSpriteName_rawFemale() {
        let name = SpriteAssets.walkingSpriteName(genderRaw: "female", frame: 6)
        XCTAssertEqual(name, "female_walking_6")
    }

    // MARK: - All Asset Names

    func testAllAssetNames_hasCorrectCount() {
        // 2 genders x 3 states x 2 frames = 12 state sprites
        // 2 genders x 32 walking frames = 64 walking sprites (matches the asset catalog)
        XCTAssertEqual(SpriteAssets.walkingFrameCount, 32)
        XCTAssertEqual(SpriteAssets.allAssetNames.count, 12 + 2 * SpriteAssets.walkingFrameCount)
    }

    func testAllAssetNames_containsStateSprites() {
        let all = SpriteAssets.allAssetNames
        XCTAssertTrue(all.contains("male_vital_1"))
        XCTAssertTrue(all.contains("male_vital_2"))
        XCTAssertTrue(all.contains("female_neutral_1"))
        XCTAssertTrue(all.contains("female_low_2"))
    }

    func testAllAssetNames_containsWalkingSprites() {
        let all = SpriteAssets.allAssetNames
        XCTAssertTrue(all.contains("male_walking_1"))
        XCTAssertTrue(all.contains("male_walking_8"))
        XCTAssertTrue(all.contains("female_walking_1"))
        XCTAssertTrue(all.contains("female_walking_8"))
    }

    func testAllAssetNames_noEmptyStrings() {
        let all = SpriteAssets.allAssetNames
        XCTAssertFalse(all.contains(""))
        XCTAssertFalse(all.contains(where: { $0.isEmpty }))
    }

    func testAllAssetNames_noDuplicates() {
        let all = SpriteAssets.allAssetNames
        let uniqueSet = Set(all)
        XCTAssertEqual(all.count, uniqueSet.count, "There should be no duplicate asset names")
    }
}
