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
}
