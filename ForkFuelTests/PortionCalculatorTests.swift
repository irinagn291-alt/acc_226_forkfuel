import XCTest
@testable import ForkFuel

final class PortionCalculatorTests: XCTestCase {
    func testScalesFromPerHundred() {
        let product = sample(kcal: 200, protein: 10, carbs: 20, fat: 5)
        let portion = PortionCalculator.portion(of: product, grams: 50)
        XCTAssertEqual(portion.energyKcal, 100)
        XCTAssertEqual(portion.proteinGrams, 5)
        XCTAssertEqual(portion.carbsGrams, 10)
        XCTAssertEqual(portion.fatGrams, 2.5)
    }

    func testKilojouleFallback() {
        let kcal = PortionCalculator.energyPerHundred(kcal: nil, kilojoules: 418.4)
        XCTAssertEqual(kcal ?? 0, 100, accuracy: 0.001)
        let ignored = PortionCalculator.energyPerHundred(kcal: 90, kilojoules: 418.4)
        XCTAssertEqual(ignored, 90)
    }

    func testMissingMacroStaysUnknown() {
        let product = sample(kcal: 100, protein: nil, carbs: 10, fat: nil)
        let portion = PortionCalculator.portion(of: product, grams: 200)
        XCTAssertEqual(portion.energyKcal, 200)
        XCTAssertNil(portion.proteinGrams)
        XCTAssertEqual(portion.carbsGrams, 20)
        XCTAssertNil(portion.fatGrams)
        XCTAssertNotEqual(portion.proteinGrams, 0)
        XCTAssertNotEqual(portion.fatGrams, 0)
    }

    private func sample(kcal: Double?, protein: Double?, carbs: Double?, fat: Double?) -> FuelProductSnapshot {
        FuelProductSnapshot(
            barcode: "000",
            displayName: "Sample",
            brandMark: nil,
            energyKcalPerHundred: kcal,
            proteinPerHundred: protein,
            carbsPerHundred: carbs,
            fatPerHundred: fat,
            imageRemotePath: nil,
            bundledAssetKey: nil,
            lastRefreshAt: Date()
        )
    }
}
