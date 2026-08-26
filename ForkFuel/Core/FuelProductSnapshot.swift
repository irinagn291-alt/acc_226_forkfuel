import Foundation

/// Sendable product value. SwiftData models never leave the vault actor.
struct FuelProductSnapshot: Equatable, Sendable, Identifiable, Hashable {
    var barcode: String
    var displayName: String
    var brandMark: String?
    var energyKcalPerHundred: Double?
    var proteinPerHundred: Double?
    var carbsPerHundred: Double?
    var fatPerHundred: Double?
    var imageRemotePath: String?
    var bundledAssetKey: String?
    var lastRefreshAt: Date

    var id: String { barcode }

    var hasUsableName: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var energyIsUnknown: Bool {
        energyKcalPerHundred == nil
    }
}

/// One logged or planned portion.
struct FuelIntakeRecord: Equatable, Sendable, Identifiable, Hashable {
    var id: UUID
    var product: FuelProductSnapshot
    var grams: Double
    var slot: FuelSlot
    var dayKey: Date
    var isConsumed: Bool

    var portion: PortionResult {
        PortionCalculator.portion(of: product, grams: grams)
    }
}

struct FuelIntakeDraft: Equatable, Sendable {
    var product: FuelProductSnapshot
    var grams: Double
    var slot: FuelSlot
    var dayKey: Date
    var isConsumed: Bool
}

struct WishSnapshot: Equatable, Sendable, Identifiable, Hashable {
    var id: UUID
    var product: FuelProductSnapshot
    var addedAt: Date
}

struct FuelDaySnapshot: Equatable, Sendable {
    var dayKey: Date
    var kind: TrainingDayKind
    var targets: FuelMacroTargets
    var consumed: [FuelIntakeRecord]
    var planned: [FuelIntakeRecord]
}

enum NutritionFailure: Error, Equatable, Sendable {
    case notFound
    case transport
    case decoding
    case cancelled
}
