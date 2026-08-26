import Foundation
import SwiftData
import ComposableArchitecture

/// TCA-facing persistence client. Maps actor work to Sendable snapshots.
struct FuelVaultClient: Sendable {
    var bootstrapShelf: @Sendable () async throws -> Void
    var cacheProduct: @Sendable (FuelProductSnapshot) async throws -> Void
    var product: @Sendable (String) async throws -> FuelProductSnapshot?
    var persistIntake: @Sendable (FuelIntakeDraft) async throws -> FuelIntakeRecord
    var eraseIntake: @Sendable (UUID) async throws -> Void
    var markConsumed: @Sendable (UUID, Date) async throws -> FuelIntakeRecord?
    var loadDay: @Sendable (Date, TrainingDayPolicy) async throws -> FuelDaySnapshot
    var plannedHorizon: @Sendable (Date, Int) async throws -> [FuelIntakeRecord]
    var upsertWish: @Sendable (FuelProductSnapshot) async throws -> (WishSnapshot, Bool)
    var wishContains: @Sendable (String) async throws -> Bool
    var wishes: @Sendable () async throws -> [WishSnapshot]
    var eraseWish: @Sendable (UUID) async throws -> Void
    var writeTargets: @Sendable (FuelMacroTargets, FuelMacroTargets) async throws -> Void
    var loadTargets: @Sendable () async throws -> (FuelMacroTargets, FuelMacroTargets)
    var tagDay: @Sendable (Date, TrainingDayKind) async throws -> Void
    var tags: @Sendable (Date, Int) async throws -> [Date: TrainingDayKind]
    var resetAllData: @Sendable () async throws -> Void
    var seedDemoDay: @Sendable (Date) async throws -> Void
}

enum FuelVaultClientKey: DependencyKey {
    static let liveValue = FuelVaultClient.unimplemented
    static let testValue = FuelVaultClient.unimplemented
}

extension DependencyValues {
    var fuelVault: FuelVaultClient {
        get { self[FuelVaultClientKey.self] }
        set { self[FuelVaultClientKey.self] = newValue }
    }
}

extension FuelVaultClient {
    static func live(container: ModelContainer) -> FuelVaultClient {
        let actor = FuelVaultActor(modelContainer: container)
        return FuelVaultClient(
            bootstrapShelf: { try await actor.bootstrapShelf(FuelShelfCatalog.items) },
            cacheProduct: { try await actor.cacheProduct($0) },
            product: { try await actor.product(barcode: $0) },
            persistIntake: { try await actor.persistIntake($0) },
            eraseIntake: { try await actor.eraseIntake(id: $0) },
            markConsumed: { try await actor.markConsumed(id: $0, dayKey: $1) },
            loadDay: { try await actor.loadDay($0, policy: $1) },
            plannedHorizon: { try await actor.plannedHorizon(from: $0, days: $1) },
            upsertWish: { try await actor.upsertWish($0) },
            wishContains: { try await actor.wishContains(barcode: $0) },
            wishes: { try await actor.wishes() },
            eraseWish: { try await actor.eraseWish(id: $0) },
            writeTargets: { try await actor.writeTargets(training: $0, rest: $1) },
            loadTargets: { try await actor.loadTargetPair() },
            tagDay: { try await actor.tag(dayKey: $0, kind: $1) },
            tags: { try await actor.tags(from: $0, days: $1) },
            resetAllData: { try await actor.resetAllData() },
            seedDemoDay: { try await actor.seedDemoDay(today: $0) }
        )
    }

    static let unimplemented = FuelVaultClient(
        bootstrapShelf: { throw NutritionFailure.transport },
        cacheProduct: { _ in throw NutritionFailure.transport },
        product: { _ in nil },
        persistIntake: { _ in throw NutritionFailure.transport },
        eraseIntake: { _ in },
        markConsumed: { _, _ in nil },
        loadDay: { _, _ in
            FuelDaySnapshot(
                dayKey: Date(),
                kind: .rest,
                targets: .restDefault,
                consumed: [],
                planned: []
            )
        },
        plannedHorizon: { _, _ in [] },
        upsertWish: { product in
            (WishSnapshot(id: UUID(), product: product, addedAt: Date()), false)
        },
        wishContains: { _ in false },
        wishes: { [] },
        eraseWish: { _ in },
        writeTargets: { _, _ in },
        loadTargets: { (.trainingDefault, .restDefault) },
        tagDay: { _, _ in },
        tags: { _, _ in [:] },
        resetAllData: { },
        seedDemoDay: { _ in }
    )
}
