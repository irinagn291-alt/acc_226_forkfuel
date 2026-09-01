import SwiftUI
import ComposableArchitecture

/// Primary session screen. Log is inline; navigation is delegated to `RootFeature`.
@MainActor
struct TodayCanvas: View {
    @Bindable var store: StoreOf<TodayFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                header
                kindToggle
                energyCard
                macroRow
                FuelCitationBoard()
                AthleticActionButton(title: "Find fuel") {
                    store.send(.openCatalog)
                }
                .accessibilityLabel("Find fuel in the catalog")
                navigationRow
                slotStrip
                inlineLog
            }
            .padding(.horizontal, AthleticSpace.x(2))
            .padding(.bottom, AthleticSpace.x(3))
        }
        .scrollDismissesKeyboard(.immediately)
        .background(AthleticPalette.background.ignoresSafeArea())
        .background { AthleticChrome.textureBackdrop() }
        .navigationTitle("Today's Fuel")
        .navigationBarTitleDisplayMode(.inline)
        .overlay { successFlash }
        .task { await store.send(.task).finish() }
        .confirmationDialog(
            "Remove this fuel from the log?",
            isPresented: Binding(
                get: { store.pendingDelete != nil },
                set: { if !$0 { store.send(.cancelDelete) } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { store.send(.confirmDelete) }
            Button("Keep", role: .cancel) { store.send(.cancelDelete) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Image("ffl_HeaderDecor")
                .resizable()
                .scaledToFill()
                .frame(height: 72)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                .accessibilityHidden(true)
            HStack {
                dayButton("Previous day", system: "chevron.left") { store.send(.shiftDay(-1)) }
                Spacer()
                Text(store.dayKey, style: .date)
                    .font(AthleticTypeScale.title())
                    .foregroundStyle(AthleticPalette.ink)
                    .lineLimit(1)
                Spacer()
                dayButton("Next day", system: "chevron.right") { store.send(.shiftDay(1)) }
            }
        }
    }

    private func dayButton(_ label: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.body.weight(.semibold))
                .foregroundStyle(AthleticPalette.accent)
                .frame(width: AthleticSpace.tap, height: AthleticSpace.tap)
        }
        .accessibilityLabel(label)
    }

    private var kindToggle: some View {
        Button {
            store.send(.toggleKind)
        } label: {
            HStack(spacing: AthleticSpace.x(1.5)) {
                Image("ffl_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.kind.title)
                        .font(AthleticTypeScale.heading())
                        .foregroundStyle(AthleticPalette.ink)
                    Text(store.kind.subtitle)
                        .font(AthleticTypeScale.caption())
                        .foregroundStyle(AthleticPalette.muted)
                }
                Spacer()
                Text("Switch")
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.background)
                    .padding(.horizontal, AthleticSpace.x(1.5))
                    .frame(minHeight: AthleticSpace.tap)
                    .background(AthleticPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
            }
            .padding(AthleticSpace.x(1.5))
            .background(AthleticPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        }
        .accessibilityLabel("Session tag \(store.kind.title). Switch training or rest.")
    }

    private var energyCard: some View {
        let used = store.aggregate.energyKcal()
        let target = store.targets.energyKcal
        let over = used > target
        return VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Text("Energy")
                .font(AthleticTypeScale.caption())
                .foregroundStyle(AthleticPalette.muted)
            HStack(alignment: .firstTextBaseline, spacing: AthleticSpace.x(1)) {
                Text(AthleticNumbers.energyKcal(used))
                    .font(AthleticTypeScale.energyDisplay())
                    .foregroundStyle(over ? AthleticPalette.ink : AthleticPalette.accent)
                    .contentTransition(reduceMotion ? .opacity : .numericText())
                    .animation(AthleticMotion.allowed(reduceMotion: reduceMotion), value: used)
                Text("/ \(AthleticNumbers.energyKcal(target)) kcal")
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)
                    .layoutPriority(1)
            }
            meter(progress: target == 0 ? 0 : used / target, over: over)
            if over {
                Text("Over the session budget")
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.ink)
            }
            if store.aggregate.energyHasUnknown() {
                Text("Some items have unknown energy")
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.muted)
            }
        }
        .padding(AthleticSpace.x(2))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Energy \(AthleticNumbers.energyKcal(used)) of \(AthleticNumbers.energyKcal(target)) kilocalories")
    }

    private var macroRow: some View {
        VStack(spacing: AthleticSpace.x(1)) {
            macroMeter("Protein", asset: "ffl_MacroProtein", used: store.aggregate.proteinGrams(), target: store.targets.proteinGrams)
            macroMeter("Carbs", asset: "ffl_MacroCarbs", used: store.aggregate.carbsGrams(), target: store.targets.carbsGrams)
            macroMeter("Fat", asset: "ffl_MacroFat", used: store.aggregate.fatGrams(), target: store.targets.fatGrams)
        }
    }

    private func macroMeter(_ title: String, asset: String, used: Double?, target: Double) -> some View {
        let progress: Double = {
            guard let used, target > 0 else { return 0 }
            return used / target
        }()
        return HStack(spacing: AthleticSpace.x(1.5)) {
            MacroGlyph(asset: asset)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(AthleticTypeScale.body())
                        .foregroundStyle(AthleticPalette.ink)
                    Spacer()
                    Text("\(AthleticNumbers.macroGrams(used)) / \(target == 0 ? "—" : AthleticNumbers.macroGrams(target)) g")
                        .font(AthleticTypeScale.caption())
                        .foregroundStyle(AthleticPalette.muted)
                        .layoutPriority(1)
                }
                meter(progress: progress, over: progress > 1)
            }
        }
        .padding(AthleticSpace.x(1.5))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(AthleticNumbers.macroGrams(used)) of \(AthleticNumbers.macroGrams(target)) grams")
    }

    private func meter(progress: Double, over: Bool) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AthleticPalette.muted.opacity(0.35))
                Capsule()
                    .fill(over ? AthleticPalette.ink : AthleticPalette.accent)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var navigationRow: some View {
        VStack(spacing: AthleticSpace.x(1)) {
            navLink("Forward Fuel", detail: store.plannedCount == 0 ? "Nothing parked ahead" : "\(store.plannedCount) parked") {
                store.send(.openPlanner)
            }
            navLink("Buy List", detail: "Shelf you intend to grab") {
                store.send(.openWish)
            }
            navLink("Session Tags", detail: "Pre-tag Training or Rest") {
                store.send(.openHorizon)
            }
            navLink("Fuel Goals", detail: "Edit targets and reset") {
                store.send(.openGoals)
            }
        }
    }

    private func navLink(_ title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AthleticTypeScale.title())
                        .foregroundStyle(AthleticPalette.ink)
                    Text(detail)
                        .font(AthleticTypeScale.caption())
                        .foregroundStyle(AthleticPalette.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AthleticPalette.muted)
                    .accessibilityHidden(true)
            }
            .padding(AthleticSpace.x(1.5))
            .frame(minHeight: AthleticSpace.tap)
            .background(AthleticPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        }
        .accessibilityLabel(title)
        .accessibilityHint(detail)
    }

    private var slotStrip: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Text("Slots")
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            ForEach(FuelSlot.allCases) { slot in
                let rows = store.aggregate.records(in: slot)
                HStack(spacing: AthleticSpace.x(1.5)) {
                    SlotGlyph(slot: slot)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.title)
                            .font(AthleticTypeScale.body())
                            .foregroundStyle(AthleticPalette.ink)
                        Text(rows.isEmpty ? "Empty" : rows.map(\.product.displayName).joined(separator: ", "))
                            .font(AthleticTypeScale.caption())
                            .foregroundStyle(AthleticPalette.muted)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(AthleticNumbers.energyKcal(store.aggregate.subtotal(for: slot).energyKcal))
                        .font(AthleticTypeScale.title())
                        .foregroundStyle(AthleticPalette.accent)
                        .layoutPriority(1)
                }
                .padding(AthleticSpace.x(1.5))
                .background(AthleticPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(slot.title), \(rows.count) items")
            }
        }
    }

    @ViewBuilder
    private var inlineLog: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1.5)) {
            Text("Eaten")
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            if store.loadFailed {
                DesignedFailureBoard(
                    title: "The log could not load",
                    detail: "The vault did not answer. Retry to rebuild today's board.",
                    retryTitle: "Retry",
                    retry: { store.send(.refreshRequested) }
                )
            } else if store.consumed.isEmpty {
                EmptyFuelBoard(
                    asset: "ffl_EmptyLog",
                    title: "Canister is empty",
                    detail: "Park Pre-Fuel, Refuel, Recovery or a Top-Up to start the session.",
                    actionTitle: "Find fuel"
                ) { store.send(.openCatalog) }
            } else {
                ForEach(FuelSlot.allCases) { slot in
                    let rows = store.aggregate.records(in: slot)
                    if !rows.isEmpty {
                        Text(slot.title)
                            .font(AthleticTypeScale.caption())
                            .foregroundStyle(AthleticPalette.muted)
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, record in
                            logRow(record, delay: index)
                        }
                    }
                }
            }
        }
    }

    private func logRow(_ record: FuelIntakeRecord, delay: Int) -> some View {
        HStack(spacing: AthleticSpace.x(1.5)) {
            FuelThumbCanvas(product: record.product)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.product.displayName)
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.ink)
                    .lineLimit(1)
                Text("\(AthleticNumbers.grams(record.grams)) g")
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(AthleticNumbers.energyKcal(record.portion.energyKcal))
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.accent)
                .layoutPriority(1)
            Button {
                store.send(.askDelete(record.id))
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(AthleticPalette.ink)
                    .frame(width: AthleticSpace.tap, height: AthleticSpace.tap)
            }
            .accessibilityLabel("Remove \(record.product.displayName)")
        }
        .padding(AthleticSpace.x(1))
        .background(record.id == store.highlightedID ? AthleticPalette.accent.opacity(0.18) : AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        .opacity(1)
        .animation(AthleticMotion.allowed(reduceMotion: reduceMotion).delay(reduceMotion ? 0 : Double(delay) * 0.04), value: store.consumed.count)
    }

    @ViewBuilder
    private var successFlash: some View {
        if store.showSuccess {
            Image("ffl_SuccessMark")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityLabel("Fuel parked")
                .transition(.opacity)
        }
    }
}
