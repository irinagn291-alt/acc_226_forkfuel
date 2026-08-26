import XCTest
import SwiftData
@testable import ForkFuel

final class WishUniquenessTests: XCTestCase {
    func testDuplicateBarcodeUpdatesExistingRow() async throws {
        let container = try FuelStoreBootstrap.makeContainer(inMemory: true).get()
        let actor = FuelVaultActor(modelContainer: container)
        try await actor.bootstrapShelf(FuelShelfCatalog.items)
        let oats = FuelShelfCatalog.items[4]
        let first = try await actor.upsertWish(oats)
        XCTAssertFalse(first.alreadySaved)
        let second = try await actor.upsertWish(oats)
        XCTAssertTrue(second.alreadySaved)
        let wishes = try await actor.wishes()
        XCTAssertEqual(wishes.count, 1)
        XCTAssertEqual(wishes.first?.product.barcode, oats.barcode)
    }
}
