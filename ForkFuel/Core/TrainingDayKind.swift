import Foundation

/// Training vs Rest. Each kind carries its own macro target set.
enum TrainingDayKind: String, CaseIterable, Sendable, Equatable, Identifiable {
    case training
    case rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .training: "Training"
        case .rest: "Rest"
        }
    }

    var subtitle: String {
        switch self {
        case .training: "Session fuel"
        case .rest: "Recovery fuel"
        }
    }
}

/// Daily energy and macro budgets. Derived totals are never stored.
struct FuelMacroTargets: Equatable, Sendable {
    var energyKcal: Double
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double

    static let trainingDefault = FuelMacroTargets(
        energyKcal: 2_800,
        proteinGrams: 180,
        carbsGrams: 300,
        fatGrams: 80
    )

    static let restDefault = FuelMacroTargets(
        energyKcal: 2_100,
        proteinGrams: 140,
        carbsGrams: 220,
        fatGrams: 65
    )

    var isValid: Bool {
        energyKcal >= 800 && energyKcal <= 8_000
            && proteinGrams >= 0 && proteinGrams <= 400
            && carbsGrams >= 0 && carbsGrams <= 800
            && fatGrams >= 0 && fatGrams <= 300
    }
}
