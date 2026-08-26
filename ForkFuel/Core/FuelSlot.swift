import Foundation

/// Pre-Fuel, Refuel, Recovery, Top-Up. Top-Up is eaten-only.
enum FuelSlot: String, CaseIterable, Sendable, Equatable, Identifiable {
    case preFuel
    case refuel
    case recovery
    case topUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preFuel: "Pre-Fuel"
        case .refuel: "Refuel"
        case .recovery: "Recovery"
        case .topUp: "Top-Up"
        }
    }

    var canPlanAhead: Bool {
        self != .topUp
    }

    var assetName: String {
        switch self {
        case .preFuel: "ffl_SlotPreFuel"
        case .refuel: "ffl_SlotRefuel"
        case .recovery: "ffl_SlotRecovery"
        case .topUp: "ffl_SlotTopUp"
        }
    }

    static func suggested(at date: Date, calendar: Calendar = .current) -> FuelSlot {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 0..<11: return .preFuel
        case 11..<16: return .refuel
        case 16..<21: return .recovery
        default: return .topUp
        }
    }
}
