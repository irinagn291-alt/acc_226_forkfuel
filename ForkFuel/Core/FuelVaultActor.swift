import Foundation
import SwiftData

/// Background SwiftData seam. `ModelContext` stays inside this `@ModelActor`.
@ModelActor
actor FuelVaultActor {
    func bootstrapShelf(_ products: [FuelProductSnapshot]) throws {
        for product in products {
            _ = try upsertCatalog(product)
        }
        try persist()
        try ensureDefaultTargets()
    }

    func cacheProduct(_ product: FuelProductSnapshot) throws {
        _ = try upsertCatalog(product)
        try persist()
    }

    func product(barcode: String) throws -> FuelProductSnapshot? {
        try catalog(barcode: barcode).map(snapshot(from:))
    }

    func persistIntake(_ draft: FuelIntakeDraft) throws -> FuelIntakeRecord {
        let catalog = try upsertCatalog(draft.product)
        let entry = FuelEntry(
            grams: draft.grams,
            slotRaw: draft.slot.rawValue,
            dayKey: draft.dayKey,
            isConsumed: draft.isConsumed,
            catalogItem: catalog
        )
        modelContext.insert(entry)
        try persist()
        return record(from: entry, product: draft.product)
    }

    func eraseIntake(id: UUID) throws {
        let key = id
        let predicate = #Predicate<FuelEntry> { $0.recordKey == key }
        let found = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        for entry in found {
            modelContext.delete(entry)
        }
        try persist()
    }

    func markConsumed(id: UUID, dayKey: Date) throws -> FuelIntakeRecord? {
        let key = id
        let predicate = #Predicate<FuelEntry> { $0.recordKey == key }
        guard let entry = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first else {
            return nil
        }
        entry.isConsumed = true
        entry.dayKey = dayKey
        try persist()
        guard let item = entry.catalogItem else { return nil }
        return record(from: entry, product: snapshot(from: item))
    }

    func loadDay(_ dayKey: Date, policy: TrainingDayPolicy) throws -> FuelDaySnapshot {
        let key = dayKey
        let predicate = #Predicate<FuelEntry> { $0.dayKey == key }
        let entries = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        var consumed: [FuelIntakeRecord] = []
        var planned: [FuelIntakeRecord] = []
        for entry in entries {
            guard let item = entry.catalogItem else { continue }
            let mapped = record(from: entry, product: snapshot(from: item))
            if mapped.isConsumed {
                consumed.append(mapped)
            } else {
                planned.append(mapped)
            }
        }
        let pair = try loadTargetPair()
        let storedKind = try storedKind(on: dayKey)
        let kind = policy.resolvedKind(stored: storedKind, dayKey: dayKey)
        let targets = policy.targets(kind: kind, training: pair.training, rest: pair.rest)
        return FuelDaySnapshot(
            dayKey: dayKey,
            kind: kind,
            targets: targets,
            consumed: consumed,
            planned: planned
        )
    }

    func plannedHorizon(from start: Date, days: Int) throws -> [FuelIntakeRecord] {
        let end = DayKeyCalendar.addingDays(days, to: start)
        let startKey = start
        let endKey = end
        let predicate = #Predicate<FuelEntry> { entry in
            entry.isConsumed == false && entry.dayKey >= startKey && entry.dayKey < endKey
        }
        let entries = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        return entries.compactMap { entry in
            guard let item = entry.catalogItem else { return nil }
            return record(from: entry, product: snapshot(from: item))
        }
        .sorted { lhs, rhs in
            if lhs.dayKey != rhs.dayKey { return lhs.dayKey < rhs.dayKey }
            return lhs.slot.rawValue < rhs.slot.rawValue
        }
    }

    func upsertWish(_ product: FuelProductSnapshot) throws -> (item: WishSnapshot, alreadySaved: Bool) {
        let catalog = try upsertCatalog(product)
        let code = product.barcode
        let predicate = #Predicate<WishItem> { $0.barcodeToken == code }
        if let existing = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            existing.addedAt = Date()
            existing.catalogItem = catalog
            try persist()
            return (WishSnapshot(id: existing.recordKey, product: product, addedAt: existing.addedAt), true)
        }
        let wish = WishItem(barcodeToken: product.barcode, catalogItem: catalog)
        modelContext.insert(wish)
        try persist()
        return (WishSnapshot(id: wish.recordKey, product: product, addedAt: wish.addedAt), false)
    }

    func wishContains(barcode: String) throws -> Bool {
        let code = barcode
        let predicate = #Predicate<WishItem> { $0.barcodeToken == code }
        return try modelContext.fetchCount(FetchDescriptor(predicate: predicate)) > 0
    }

    func wishes() throws -> [WishSnapshot] {
        let items = try modelContext.fetch(FetchDescriptor<WishItem>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)]))
        return items.compactMap { wish in
            guard let item = wish.catalogItem else { return nil }
            return WishSnapshot(id: wish.recordKey, product: snapshot(from: item), addedAt: wish.addedAt)
        }
    }

    func eraseWish(id: UUID) throws {
        let key = id
        let predicate = #Predicate<WishItem> { $0.recordKey == key }
        for wish in try modelContext.fetch(FetchDescriptor(predicate: predicate)) {
            modelContext.delete(wish)
        }
        try persist()
    }

    func writeTargets(training: FuelMacroTargets, rest: FuelMacroTargets) throws {
        try writeTarget(kind: .training, values: training)
        try writeTarget(kind: .rest, values: rest)
        try persist()
    }

    func loadTargetPair() throws -> (training: FuelMacroTargets, rest: FuelMacroTargets) {
        try ensureDefaultTargets()
        return (
            try target(for: .training) ?? .trainingDefault,
            try target(for: .rest) ?? .restDefault
        )
    }

    func tag(dayKey: Date, kind: TrainingDayKind) throws {
        let key = dayKey
        let predicate = #Predicate<TrainingTag> { $0.dayKey == key }
        if let existing = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            existing.kindRaw = kind.rawValue
        } else {
            modelContext.insert(TrainingTag(dayKey: dayKey, kindRaw: kind.rawValue))
        }
        try persist()
    }

    func storedKind(on dayKey: Date) throws -> TrainingDayKind? {
        let key = dayKey
        let predicate = #Predicate<TrainingTag> { $0.dayKey == key }
        guard let raw = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first?.kindRaw else {
            return nil
        }
        return TrainingDayKind(rawValue: raw)
    }

    func tags(from start: Date, days: Int) throws -> [Date: TrainingDayKind] {
        let end = DayKeyCalendar.addingDays(days, to: start)
        let startKey = start
        let endKey = end
        let predicate = #Predicate<TrainingTag> { tag in
            tag.dayKey >= startKey && tag.dayKey < endKey
        }
        let rows = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        var map: [Date: TrainingDayKind] = [:]
        for row in rows {
            if let kind = TrainingDayKind(rawValue: row.kindRaw) {
                map[row.dayKey] = kind
            }
        }
        return map
    }

    func resetAllData() throws {
        try deleteAll(FuelEntry.self)
        try deleteAll(WishItem.self)
        try deleteAll(TrainingTag.self)
        try deleteAll(FuelTarget.self)
        try deleteAll(FuelCatalogItem.self)
        try persist()
        try bootstrapShelf(FuelShelfCatalog.items)
    }

    func seedDemoDay(today: Date) throws {
        try bootstrapShelf(FuelShelfCatalog.items)
        try tag(dayKey: today, kind: .training)
        let oats = FuelShelfCatalog.items[4]
        let kefir = FuelShelfCatalog.items[2]
        let cakes = FuelShelfCatalog.items[1]
        let couscous = FuelShelfCatalog.items[3]
        let potato = FuelShelfCatalog.items[5]
        _ = try persistIntake(FuelIntakeDraft(product: oats, grams: 80, slot: .preFuel, dayKey: today, isConsumed: true))
        _ = try persistIntake(FuelIntakeDraft(product: kefir, grams: 250, slot: .refuel, dayKey: today, isConsumed: true))
        _ = try persistIntake(FuelIntakeDraft(product: cakes, grams: 30, slot: .topUp, dayKey: today, isConsumed: true))
        let tomorrow = DayKeyCalendar.addingDays(1, to: today)
        _ = try persistIntake(FuelIntakeDraft(product: couscous, grams: 120, slot: .recovery, dayKey: tomorrow, isConsumed: false))
        _ = try upsertWish(potato)
    }

    private func upsertCatalog(_ product: FuelProductSnapshot) throws -> FuelCatalogItem {
        let code = product.barcode
        let predicate = #Predicate<FuelCatalogItem> { $0.barcode == code }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            existing.displayName = product.displayName
            existing.brandMark = product.brandMark
            existing.energyKcalPerHundred = product.energyKcalPerHundred
            existing.proteinPerHundred = product.proteinPerHundred
            existing.carbsPerHundred = product.carbsPerHundred
            existing.fatPerHundred = product.fatPerHundred
            existing.imageRemotePath = product.imageRemotePath
            existing.bundledAssetKey = product.bundledAssetKey
            existing.lastRefreshAt = product.lastRefreshAt
            return existing
        }
        let item = FuelCatalogItem(
            barcode: product.barcode,
            displayName: product.displayName,
            brandMark: product.brandMark,
            energyKcalPerHundred: product.energyKcalPerHundred,
            proteinPerHundred: product.proteinPerHundred,
            carbsPerHundred: product.carbsPerHundred,
            fatPerHundred: product.fatPerHundred,
            imageRemotePath: product.imageRemotePath,
            bundledAssetKey: product.bundledAssetKey,
            lastRefreshAt: product.lastRefreshAt
        )
        modelContext.insert(item)
        return item
    }

    private func catalog(barcode: String) throws -> FuelCatalogItem? {
        let code = barcode
        let predicate = #Predicate<FuelCatalogItem> { $0.barcode == code }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func writeTarget(kind: TrainingDayKind, values: FuelMacroTargets) throws {
        let raw = kind.rawValue
        let predicate = #Predicate<FuelTarget> { $0.kindRaw == raw }
        if let existing = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            existing.energyKcal = values.energyKcal
            existing.proteinGrams = values.proteinGrams
            existing.carbsGrams = values.carbsGrams
            existing.fatGrams = values.fatGrams
        } else {
            modelContext.insert(
                FuelTarget(
                    kindRaw: raw,
                    energyKcal: values.energyKcal,
                    proteinGrams: values.proteinGrams,
                    carbsGrams: values.carbsGrams,
                    fatGrams: values.fatGrams
                )
            )
        }
    }

    private func target(for kind: TrainingDayKind) throws -> FuelMacroTargets? {
        let raw = kind.rawValue
        let predicate = #Predicate<FuelTarget> { $0.kindRaw == raw }
        guard let row = try modelContext.fetch(FetchDescriptor(predicate: predicate)).first else {
            return nil
        }
        return FuelMacroTargets(
            energyKcal: row.energyKcal,
            proteinGrams: row.proteinGrams,
            carbsGrams: row.carbsGrams,
            fatGrams: row.fatGrams
        )
    }

    private func ensureDefaultTargets() throws {
        if try target(for: .training) == nil {
            try writeTarget(kind: .training, values: .trainingDefault)
        }
        if try target(for: .rest) == nil {
            try writeTarget(kind: .rest, values: .restDefault)
        }
        try persist()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let rows = try modelContext.fetch(FetchDescriptor<T>())
        for row in rows {
            modelContext.delete(row)
        }
    }

    private func persist() throws {
        try modelContext.save()
    }

    private func snapshot(from item: FuelCatalogItem) -> FuelProductSnapshot {
        FuelProductSnapshot(
            barcode: item.barcode,
            displayName: item.displayName,
            brandMark: item.brandMark,
            energyKcalPerHundred: item.energyKcalPerHundred,
            proteinPerHundred: item.proteinPerHundred,
            carbsPerHundred: item.carbsPerHundred,
            fatPerHundred: item.fatPerHundred,
            imageRemotePath: item.imageRemotePath,
            bundledAssetKey: item.bundledAssetKey,
            lastRefreshAt: item.lastRefreshAt
        )
    }

    private func record(from entry: FuelEntry, product: FuelProductSnapshot) -> FuelIntakeRecord {
        FuelIntakeRecord(
            id: entry.recordKey,
            product: product,
            grams: entry.grams,
            slot: FuelSlot(rawValue: entry.slotRaw) ?? .refuel,
            dayKey: entry.dayKey,
            isConsumed: entry.isConsumed
        )
    }
}
