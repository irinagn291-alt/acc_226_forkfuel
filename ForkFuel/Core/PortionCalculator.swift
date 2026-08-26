import Foundation

struct PortionResult: Equatable, Sendable {
    var energyKcal: Double?
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?
}

/// Scales per-100 g nutriments. Missing macros stay missing. Never rounds stored values.
enum PortionCalculator {
    static let kilojouleFactor = 4.184
    static let minimumGrams = 1.0
    static let maximumGrams = 2_000.0

    static func energyPerHundred(kcal: Double?, kilojoules: Double?) -> Double? {
        if let kcal {
            return kcal
        }
        if let kilojoules {
            return kilojoules / kilojouleFactor
        }
        return nil
    }

    static func scaled(_ perHundred: Double?, grams: Double) -> Double? {
        guard let perHundred else { return nil }
        return perHundred * grams / 100
    }

    static func portion(of product: FuelProductSnapshot, grams: Double) -> PortionResult {
        PortionResult(
            energyKcal: scaled(product.energyKcalPerHundred, grams: grams),
            proteinGrams: scaled(product.proteinPerHundred, grams: grams),
            carbsGrams: scaled(product.carbsPerHundred, grams: grams),
            fatGrams: scaled(product.fatPerHundred, grams: grams)
        )
    }

    static func isGramsAcceptable(_ grams: Double) -> Bool {
        grams >= minimumGrams && grams <= maximumGrams && grams.isFinite
    }
}
