import Foundation

/// Pure aggregation over a day's intake. Totals are computed, never stored.
struct FuelIntakeAggregate: Equatable, Sendable {
    var records: [FuelIntakeRecord]

    init(records: [FuelIntakeRecord]) {
        self.records = records
    }

    func groupedBySlot() -> [FuelSlot: [FuelIntakeRecord]] {
        Dictionary(grouping: records, by: \.slot)
    }

    func records(in slot: FuelSlot) -> [FuelIntakeRecord] {
        records.filter { $0.slot == slot }
    }

    func energyKcal() -> Double {
        records.compactMap(\.portion.energyKcal).reduce(0, +)
    }

    func proteinGrams() -> Double? {
        sumMacro(\.proteinGrams)
    }

    func carbsGrams() -> Double? {
        sumMacro(\.carbsGrams)
    }

    func fatGrams() -> Double? {
        sumMacro(\.fatGrams)
    }

    func energyHasUnknown() -> Bool {
        records.contains { $0.portion.energyKcal == nil }
    }

    func subtotal(for slot: FuelSlot) -> PortionResult {
        let slice = records(in: slot)
        return PortionResult(
            energyKcal: slice.compactMap(\.portion.energyKcal).reduce(0, +),
            proteinGrams: sum(slice, \.proteinGrams),
            carbsGrams: sum(slice, \.carbsGrams),
            fatGrams: sum(slice, \.fatGrams)
        )
    }

    func remaining(against targets: FuelMacroTargets) -> (energy: Double, protein: Double?, carbs: Double?, fat: Double?) {
        (
            targets.energyKcal - energyKcal(),
            proteinGrams().map { targets.proteinGrams - $0 },
            carbsGrams().map { targets.carbsGrams - $0 },
            fatGrams().map { targets.fatGrams - $0 }
        )
    }

    private func sumMacro(_ key: KeyPath<PortionResult, Double?>) -> Double? {
        sum(records, key)
    }

    private func sum(_ items: [FuelIntakeRecord], _ key: KeyPath<PortionResult, Double?>) -> Double? {
        let values = items.compactMap { $0.portion[keyPath: key] }
        if values.isEmpty, items.contains(where: { $0.portion[keyPath: key] == nil }) {
            return nil
        }
        if values.isEmpty { return nil }
        return values.reduce(0, +)
    }
}
