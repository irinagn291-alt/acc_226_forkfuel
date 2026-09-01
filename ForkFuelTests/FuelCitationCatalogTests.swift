import XCTest
@testable import ForkFuel

final class FuelCitationCatalogTests: XCTestCase {
    func testEveryCitationIsHTTPSAndReachableAsURL() {
        XCTAssertFalse(FuelCitationCatalog.entries.isEmpty)
        for entry in FuelCitationCatalog.entries {
            XCTAssertEqual(entry.url.scheme, "https")
            XCTAssertFalse(entry.title.isEmpty)
            XCTAssertFalse(entry.detail.isEmpty)
        }
    }
}
