import Foundation
import SwiftData

/// Version 1 schema. Retrofitting migration later is the expensive mistake this avoids.
enum FuelStoreSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FuelCatalogItem.self, FuelEntry.self, FuelTarget.self, TrainingTag.self, WishItem.self]
    }
}

enum FuelMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FuelStoreSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

enum FuelStoreBootstrap {
    static func makeContainer(inMemory: Bool = false) -> Result<ModelContainer, Error> {
        let schema = Schema(versionedSchema: FuelStoreSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: FuelMigrationPlan.self,
                configurations: [configuration]
            )
            return .success(container)
        } catch {
            return .failure(error)
        }
    }
}
