import Foundation

/// Bundled offline shelf. Barcodes and nutriments stay exactly as specified.
enum FuelShelfCatalog {
    static let bundledAssetKey = "ffl_ProductPlaceholder"

    static let items: [FuelProductSnapshot] = [
        item(
            barcode: "0016229906139",
            name: "Coconut Milk",
            brand: "Shelf",
            kcal: 230,
            protein: 2.3,
            carbs: 5.5,
            fat: 23.8
        ),
        item(
            barcode: "5411188110316",
            name: "Rice Cakes",
            brand: "Shelf",
            kcal: 387,
            protein: 8.0,
            carbs: 81.5,
            fat: 2.8
        ),
        item(
            barcode: "4607091382010",
            name: "Kefir",
            brand: "Shelf",
            kcal: 41,
            protein: 3.3,
            carbs: 4.1,
            fat: 1.0
        ),
        item(
            barcode: "3038350208002",
            name: "Couscous",
            brand: "Shelf",
            kcal: 376,
            protein: 12.8,
            carbs: 77.4,
            fat: 0.6
        ),
        item(
            barcode: "3013710000201",
            name: "Rolled Oats",
            brand: "Shelf",
            kcal: 379,
            protein: 13.2,
            carbs: 67.7,
            fat: 6.5
        ),
        item(
            barcode: "0033383401003",
            name: "Sweet Potato",
            brand: "Shelf",
            kcal: 86,
            protein: 1.6,
            carbs: 20.1,
            fat: 0.1
        ),
        item(
            barcode: "7394376616037",
            name: "Oat Milk",
            brand: "Oatly",
            kcal: 61,
            protein: 1.1,
            carbs: 7.1,
            fat: 3.0
        ),
    ]

    static func matches(terms: String) -> [FuelProductSnapshot] {
        let needle = terms.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return items }
        return items.filter { product in
            product.displayName.lowercased().contains(needle)
                || (product.brandMark?.lowercased().contains(needle) ?? false)
                || product.barcode.contains(needle)
        }
    }

    static func item(barcode: String) -> FuelProductSnapshot? {
        let candidates = Set(BarcodeNormaliser.candidates(from: barcode) + [barcode])
        return items.first { candidates.contains($0.barcode) }
    }

    static func merge(remote: [FuelProductSnapshot], local: [FuelProductSnapshot]) -> [FuelProductSnapshot] {
        var seen = Set<String>()
        var merged: [FuelProductSnapshot] = []
        for product in local + remote where product.hasUsableName {
            if seen.insert(product.barcode).inserted {
                merged.append(product)
            }
        }
        return merged
    }

    private static func item(
        barcode: String,
        name: String,
        brand: String,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) -> FuelProductSnapshot {
        FuelProductSnapshot(
            barcode: barcode,
            displayName: name,
            brandMark: brand,
            energyKcalPerHundred: kcal,
            proteinPerHundred: protein,
            carbsPerHundred: carbs,
            fatPerHundred: fat,
            imageRemotePath: nil,
            bundledAssetKey: bundledAssetKey,
            lastRefreshAt: Date(timeIntervalSince1970: 0)
        )
    }
}
