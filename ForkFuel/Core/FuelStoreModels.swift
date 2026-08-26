import Foundation
import SwiftData

/// Cached catalogue row. Unique barcode makes repeat inserts behave as upserts.
@Model
final class FuelCatalogItem {
    @Attribute(.unique) var barcode: String
    var displayName: String
    var brandMark: String?
    var energyKcalPerHundred: Double?
    var proteinPerHundred: Double?
    var carbsPerHundred: Double?
    var fatPerHundred: Double?
    var imageRemotePath: String?
    var bundledAssetKey: String?
    var lastRefreshAt: Date

    @Relationship(deleteRule: .nullify, inverse: \FuelEntry.catalogItem)
    var entries: [FuelEntry]

    @Relationship(deleteRule: .nullify, inverse: \WishItem.catalogItem)
    var wishes: [WishItem]

    init(
        barcode: String,
        displayName: String,
        brandMark: String? = nil,
        energyKcalPerHundred: Double? = nil,
        proteinPerHundred: Double? = nil,
        carbsPerHundred: Double? = nil,
        fatPerHundred: Double? = nil,
        imageRemotePath: String? = nil,
        bundledAssetKey: String? = nil,
        lastRefreshAt: Date = Date()
    ) {
        self.barcode = barcode
        self.displayName = displayName
        self.brandMark = brandMark
        self.energyKcalPerHundred = energyKcalPerHundred
        self.proteinPerHundred = proteinPerHundred
        self.carbsPerHundred = carbsPerHundred
        self.fatPerHundred = fatPerHundred
        self.imageRemotePath = imageRemotePath
        self.bundledAssetKey = bundledAssetKey
        self.lastRefreshAt = lastRefreshAt
        self.entries = []
        self.wishes = []
    }
}

/// Eaten or planned portion. `dayKey` is `Calendar.startOfDay`.
@Model
final class FuelEntry {
    var recordKey: UUID
    var grams: Double
    var slotRaw: String
    var dayKey: Date
    var isConsumed: Bool

    /// Inverse of `FuelCatalogItem.entries`.
    var catalogItem: FuelCatalogItem?

    init(
        recordKey: UUID = UUID(),
        grams: Double,
        slotRaw: String,
        dayKey: Date,
        isConsumed: Bool,
        catalogItem: FuelCatalogItem? = nil
    ) {
        self.recordKey = recordKey
        self.grams = grams
        self.slotRaw = slotRaw
        self.dayKey = dayKey
        self.isConsumed = isConsumed
        self.catalogItem = catalogItem
    }
}

/// Macro budget for one training-day kind.
@Model
final class FuelTarget {
    @Attribute(.unique) var kindRaw: String
    var energyKcal: Double
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double

    init(
        kindRaw: String,
        energyKcal: Double,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double
    ) {
        self.kindRaw = kindRaw
        self.energyKcal = energyKcal
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }
}

/// Training vs Rest tag for a normalised day key.
@Model
final class TrainingTag {
    @Attribute(.unique) var dayKey: Date
    var kindRaw: String

    init(dayKey: Date, kindRaw: String) {
        self.dayKey = dayKey
        self.kindRaw = kindRaw
    }
}

/// Wish-list row. Unique barcode token; a duplicate updates this row.
@Model
final class WishItem {
    var recordKey: UUID
    @Attribute(.unique) var barcodeToken: String
    var addedAt: Date

    /// Inverse of `FuelCatalogItem.wishes`.
    var catalogItem: FuelCatalogItem?

    init(
        recordKey: UUID = UUID(),
        barcodeToken: String,
        addedAt: Date = Date(),
        catalogItem: FuelCatalogItem? = nil
    ) {
        self.recordKey = recordKey
        self.barcodeToken = barcodeToken
        self.addedAt = addedAt
        self.catalogItem = catalogItem
    }
}
