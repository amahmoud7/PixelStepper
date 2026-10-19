import XCTest
@testable import PixelPal

final class CosmeticCatalogTests: XCTestCase {

    /// Licensed-character skins were removed for App Review 5.2 (IP). Guard against reintroduction.
    func test_all_containsNoLicensedCharacterSkins() {
        let banned = ["luffy", "naruto", "goku", "tanjiro", "eren", "kakashi", "gojo"]
        let offenders = CosmeticCatalog.all.filter { item in
            banned.contains { item.id.lowercased().contains($0) || item.assetName.lowercased().contains($0) }
        }
        XCTAssertTrue(offenders.isEmpty, "Licensed-character cosmetics found: \(offenders.map(\.id))")
    }

    func test_all_idsAreUnique() {
        let ids = CosmeticCatalog.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func test_item_unknownID_returnsNil() {
        // Saved loadouts may still reference a removed skin; lookup must fail gracefully.
        XCTAssertNil(CosmeticCatalog.item(id: "skin_goku"))
    }
}
