import ComposableArchitecture
import XCTest
@testable import ForkFuel

@MainActor
final class SlotAssignFeatureTests: XCTestCase {
    func testPlanningAheadRemapsTopUpInReducer() async {
        let store = TestStore(
            initialState: SlotAssignFeature.State(
                product: FuelShelfCatalog.items[0],
                grams: 100,
                slot: .topUp,
                futureDay: Date()
            )
        ) {
            SlotAssignFeature()
        }
        await store.send(.plansAheadChanged(true)) {
            $0.plansAhead = true
            $0.slot = .refuel
        }
    }

    func testPickingTopUpWhilePlanningKeepsRefuel() async {
        let store = TestStore(
            initialState: SlotAssignFeature.State(
                product: FuelShelfCatalog.items[0],
                grams: 100,
                slot: .refuel,
                plansAhead: true,
                futureDay: Date()
            )
        ) {
            SlotAssignFeature()
        }
        await store.send(.slotPicked(.topUp))
    }
}
