import XCTest
import SwiftData
@testable import ForkFuel

final class PersistenceRoundTripTests: XCTestCase {
    func testWriteReloadVerify() async throws {
        let container = try FuelStoreBootstrap.makeContainer(inMemory: true).get()
        let writer = FuelVaultActor(modelContainer: container)
        try await writer.bootstrapShelf(FuelShelfCatalog.items)
        let oats = FuelShelfCatalog.items[4]
        let day = DayKeyCalendar.key(for: Date())
        let draft = FuelIntakeDraft(product: oats, grams: 80, slot: .preFuel, dayKey: day, isConsumed: true)
        let written = try await writer.persistIntake(draft)
        try await writer.tag(dayKey: day, kind: .training)
        let reader = FuelVaultActor(modelContainer: container)
        let snapshot = try await reader.loadDay(day, policy: TrainingDayPolicy())
        XCTAssertEqual(snapshot.consumed.count, 1)
        XCTAssertEqual(snapshot.consumed.first?.id, written.id)
        XCTAssertEqual(snapshot.consumed.first?.grams, 80)
        XCTAssertEqual(snapshot.kind, .training)
        XCTAssertEqual(snapshot.consumed.first?.product.barcode, oats.barcode)
    }
}
