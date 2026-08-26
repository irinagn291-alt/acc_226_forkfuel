import Foundation

/// Training-day rules: inferred kind, target selection, snack remapping.
struct TrainingDayPolicy: Equatable, Sendable {
    var weekdayDefault: TrainingDayKind = .training
    var weekendDefault: TrainingDayKind = .rest

    func inferredKind(for dayKey: Date, calendar: Calendar = .current) -> TrainingDayKind {
        let weekday = calendar.component(.weekday, from: dayKey)
        if weekday == 1 || weekday == 7 {
            return weekendDefault
        }
        return weekdayDefault
    }

    func resolvedKind(stored: TrainingDayKind?, dayKey: Date, calendar: Calendar = .current) -> TrainingDayKind {
        stored ?? inferredKind(for: dayKey, calendar: calendar)
    }

    /// Top-Up cannot be planned. Future dates remap it to Refuel (Midday).
    func slotForPlanning(_ slot: FuelSlot, plansAhead: Bool) -> FuelSlot {
        if plansAhead && slot == .topUp {
            return .refuel
        }
        return slot
    }

    func targets(
        kind: TrainingDayKind,
        training: FuelMacroTargets,
        rest: FuelMacroTargets
    ) -> FuelMacroTargets {
        kind == .training ? training : rest
    }
}
