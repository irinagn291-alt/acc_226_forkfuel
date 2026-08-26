import Foundation

/// DTO layer. Mirrors Open Food Facts JSON, then maps to `FuelProductSnapshot`.
struct OpenFoodFactsSearchDTO: Decodable, Sendable {
    var products: [OpenFoodFactsProductDTO]?
}

struct OpenFoodFactsProductEnvelopeDTO: Decodable, Sendable {
    var status: Int?
    var code: String?
    var product: OpenFoodFactsProductDTO?
}

struct OpenFoodFactsProductDTO: Decodable, Sendable {
    var code: String?
    var productName: String?
    var genericName: String?
    var brands: String?
    var imageFrontSmallURL: String?
    var nutriments: OpenFoodFactsNutrimentDTO?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case genericName = "generic_name"
        case brands
        case imageFrontSmallURL = "image_front_small_url"
        case nutriments
    }

    func mapped(fallbackCode: String, refreshedAt: Date) -> FuelProductSnapshot? {
        let resolvedCode = (code?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackCode
        let name = firstNonEmpty(productName, genericName, brands)
        guard let name else { return nil }
        let kcal = PortionCalculator.energyPerHundred(
            kcal: nutriments?.energyKcal100g?.doubleValue,
            kilojoules: nutriments?.energy100g?.doubleValue
        )
        return FuelProductSnapshot(
            barcode: resolvedCode,
            displayName: name,
            brandMark: emptyToNil(brands),
            energyKcalPerHundred: kcal,
            proteinPerHundred: nutriments?.proteins100g?.doubleValue,
            carbsPerHundred: nutriments?.carbohydrates100g?.doubleValue,
            fatPerHundred: nutriments?.fat100g?.doubleValue,
            imageRemotePath: emptyToNil(imageFrontSmallURL),
            bundledAssetKey: nil,
            lastRefreshAt: refreshedAt
        )
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            if let trimmed = emptyToNil(value) {
                return trimmed
            }
        }
        return nil
    }

    private func emptyToNil(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct OpenFoodFactsNutrimentDTO: Decodable, Sendable {
    var energyKcal100g: FlexibleScalar?
    var energy100g: FlexibleScalar?
    var proteins100g: FlexibleScalar?
    var carbohydrates100g: FlexibleScalar?
    var fat100g: FlexibleScalar?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energy100g = "energy_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}

/// Accepts a JSON number or a numeric string for every nutriment.
struct FlexibleScalar: Decodable, Equatable, Sendable {
    var doubleValue: Double?

    init(doubleValue: Double?) {
        self.doubleValue = doubleValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            doubleValue = nil
        } else if let value = try? container.decode(Double.self) {
            doubleValue = value.isFinite ? value : nil
        } else if let value = try? container.decode(Int.self) {
            doubleValue = Double(value)
        } else if let value = try? container.decode(String.self) {
            let normalised = value.replacingOccurrences(of: ",", with: ".")
            doubleValue = Double(normalised)
        } else {
            doubleValue = nil
        }
    }
}
