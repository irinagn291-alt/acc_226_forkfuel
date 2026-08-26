import XCTest
@testable import ForkFuel

final class NutritionDecodingTests: XCTestCase {
    func testDecodesStringAndMissingNutriments() throws {
        let json = """
        {
          "status": 1,
          "code": "3013710000201",
          "product": {
            "product_name": "Rolled Oats",
            "generic_name": "",
            "brands": "Shelf",
            "nutriments": {
              "energy-kcal_100g": "379",
              "proteins_100g": 13.2,
              "carbohydrates_100g": "67.7"
            }
          }
        }
        """.data(using: .utf8) ?? Data()
        let envelope = try JSONDecoder().decode(OpenFoodFactsProductEnvelopeDTO.self, from: json)
        XCTAssertEqual(envelope.status, 1)
        let product = envelope.product?.mapped(fallbackCode: "3013710000201", refreshedAt: Date())
        XCTAssertEqual(product?.displayName, "Rolled Oats")
        XCTAssertEqual(product?.energyKcalPerHundred, 379)
        XCTAssertEqual(product?.proteinPerHundred, 13.2)
        XCTAssertEqual(product?.carbsPerHundred, 67.7)
        XCTAssertNil(product?.fatPerHundred)
    }

    func testKilojouleOnlyProduct() throws {
        let json = """
        {
          "status": 1,
          "code": "1",
          "product": {
            "generic_name": "Kefir",
            "nutriments": { "energy_100g": "171.544" }
          }
        }
        """.data(using: .utf8) ?? Data()
        let envelope = try JSONDecoder().decode(OpenFoodFactsProductEnvelopeDTO.self, from: json)
        let product = envelope.product?.mapped(fallbackCode: "1", refreshedAt: Date())
        XCTAssertEqual(product?.energyKcalPerHundred ?? 0, 41, accuracy: 0.05)
    }

    func testStatusZeroIsNotFoundShape() throws {
        let json = """
        { "status": 0, "status_verbose": "product not found", "code": "000" }
        """.data(using: .utf8) ?? Data()
        let envelope = try JSONDecoder().decode(OpenFoodFactsProductEnvelopeDTO.self, from: json)
        XCTAssertEqual(envelope.status, 0)
        XCTAssertNil(envelope.product)
    }
}
