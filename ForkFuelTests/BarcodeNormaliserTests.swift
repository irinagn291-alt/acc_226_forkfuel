import XCTest
@testable import ForkFuel

final class BarcodeNormaliserTests: XCTestCase {
    func testEAN8() {
        XCTAssertEqual(BarcodeNormaliser.firstValid(from: "12345678"), "12345678")
    }

    func testEAN13() {
        XCTAssertEqual(BarcodeNormaliser.firstValid(from: "3013710000201"), "3013710000201")
    }

    func testUPCAPadsLeadingZero() {
        XCTAssertEqual(BarcodeNormaliser.normalise("036000291452"), "0036000291452")
        XCTAssertTrue(BarcodeNormaliser.candidates(from: "036000291452").contains("0036000291452"))
    }

    func testURLInput() {
        let raw = "https://world.openfoodfacts.org/product/5411188110316/rice-cakes"
        XCTAssertEqual(BarcodeNormaliser.firstValid(from: raw), "5411188110316")
    }

    func testNoValidRun() {
        XCTAssertNil(BarcodeNormaliser.firstValid(from: "abc-12-xyz"))
        XCTAssertTrue(BarcodeNormaliser.candidates(from: "no digits").isEmpty)
    }

    func testQRDigitPayload() {
        XCTAssertEqual(BarcodeNormaliser.firstValid(from: "7394376616037"), "7394376616037")
    }

    func testQROpenFoodFactsURL() {
        let raw = "https://world.openfoodfacts.org/product/3013710000201/rolled-oats"
        XCTAssertEqual(BarcodeNormaliser.firstValid(from: raw), "3013710000201")
    }

    func testQRGS1Payload() {
        let gs1 = BarcodeNormaliser.candidates(from: "https://id.gs1.org/01/03013710000201")
        XCTAssertTrue(gs1.contains("03013710000201"))
        XCTAssertTrue(gs1.contains("3013710000201"))
        XCTAssertTrue(BarcodeNormaliser.candidates(from: "(01)03013710000201").contains("3013710000201"))
    }

    func testOatMilkShelfWinsOverRemoteName() {
        let shelf = FuelShelfCatalog.item(barcode: "7394376616037")
        XCTAssertEqual(shelf?.displayName, "Oat Milk")
        let remote = FuelProductSnapshot(
            barcode: "7394376616037",
            displayName: "iKaffe",
            brandMark: "Oatly",
            energyKcalPerHundred: 61,
            proteinPerHundred: 1.1,
            carbsPerHundred: 7.1,
            fatPerHundred: 3.0,
            imageRemotePath: nil,
            bundledAssetKey: nil,
            lastRefreshAt: Date()
        )
        let merged = FuelShelfCatalog.merge(remote: [remote], local: [shelf!])
        XCTAssertEqual(merged.first?.displayName, "Oat Milk")
    }
}
