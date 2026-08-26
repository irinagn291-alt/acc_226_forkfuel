import XCTest
@testable import ForkFuel

final class FuelIntakeAggregateTests: XCTestCase {
    func testTotalsAcrossAllSlots() {
        let oats = FuelShelfCatalog.items[4]
        let kefir = FuelShelfCatalog.items[2]
        let cakes = FuelShelfCatalog.items[1]
        let couscous = FuelShelfCatalog.items[3]
        let day = DayKeyCalendar.key(for: Date())
        let records = [
            FuelIntakeRecord(id: UUID(), product: oats, grams: 100, slot: .preFuel, dayKey: day, isConsumed: true),
            FuelIntakeRecord(id: UUID(), product: kefir, grams: 100, slot: .refuel, dayKey: day, isConsumed: true),
            FuelIntakeRecord(id: UUID(), product: couscous, grams: 100, slot: .recovery, dayKey: day, isConsumed: true),
            FuelIntakeRecord(id: UUID(), product: cakes, grams: 100, slot: .topUp, dayKey: day, isConsumed: true),
        ]
        let aggregate = FuelIntakeAggregate(records: records)
        XCTAssertEqual(aggregate.energyKcal(), 379 + 41 + 376 + 387, accuracy: 0.001)
        XCTAssertEqual(aggregate.records(in: .preFuel).count, 1)
        XCTAssertEqual(aggregate.records(in: .topUp).count, 1)
        XCTAssertEqual(aggregate.subtotal(for: .refuel).energyKcal ?? 0, 41, accuracy: 0.001)
    }
}
