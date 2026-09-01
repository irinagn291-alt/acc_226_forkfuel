import SwiftUI
import ComposableArchitecture

@MainActor
struct GoalsCanvas: View {
    @Bindable var store: StoreOf<GoalsFeature>
    @State private var showContact = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                targetCard("Training targets", targets: store.training, training: true)
                targetCard("Rest targets", targets: store.rest, training: false)
                if let warning = store.warning {
                    Text(warning)
                        .font(AthleticTypeScale.caption())
                        .foregroundStyle(AthleticPalette.ink)
                }
                AthleticActionButton(
                    title: store.savedPulse ? "Saved" : "Save targets",
                    enabled: store.training.isValid && store.rest.isValid,
                    busy: store.isSaving
                ) {
                    store.send(.save)
                }
                AthleticActionButton(title: "Re-run ignition") {
                    store.send(.rerunIgnition)
                }
                Button("Reset all data") {
                    store.send(.askReset)
                }
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AthleticSpace.tap)
                .background(AthleticPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                .accessibilityLabel("Reset all data")

                Button("Contact ForkFuel") { showContact = true }
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.accent)
                    .frame(minHeight: AthleticSpace.tap)
                    .accessibilityLabel("Contact ForkFuel")

                FuelCitationBoard()
            }
            .padding(AthleticSpace.x(2))
        }
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Fuel Goals")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.send(.task).finish() }
        .confirmationDialog(
            "Erase every log, plan, wish and target?",
            isPresented: Binding(
                get: { store.pendingReset },
                set: { if !$0 { store.send(.cancelReset) } }
            ),
            titleVisibility: .visible
        ) {
            Button("Erase everything", role: .destructive) { store.send(.confirmReset) }
            Button("Keep data", role: .cancel) { store.send(.cancelReset) }
        }
        .sheet(isPresented: $showContact) {
            ContactWebSheet()
        }
    }

    private func targetCard(_ title: String, targets: FuelMacroTargets, training: Bool) -> some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1.5)) {
            Text(title)
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            tuner(
                "Energy",
                value: targets.energyKcal,
                range: 800...8000,
                format: AthleticNumbers.energyKcal(targets.energyKcal) + " kcal"
            ) { store.send(training ? .trainingEnergy($0) : .restEnergy($0)) }
            tuner(
                "Protein",
                value: targets.proteinGrams,
                range: 0...400,
                format: AthleticNumbers.macroGrams(targets.proteinGrams) + " g"
            ) { store.send(training ? .trainingProtein($0) : .restProtein($0)) }
            tuner(
                "Carbs",
                value: targets.carbsGrams,
                range: 0...800,
                format: AthleticNumbers.macroGrams(targets.carbsGrams) + " g"
            ) { store.send(training ? .trainingCarbs($0) : .restCarbs($0)) }
            tuner(
                "Fat",
                value: targets.fatGrams,
                range: 0...300,
                format: AthleticNumbers.macroGrams(targets.fatGrams) + " g"
            ) { store.send(training ? .trainingFat($0) : .restFat($0)) }
        }
        .padding(AthleticSpace.x(2))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
    }

    private func tuner(
        _ name: String,
        value: Double,
        range: ClosedRange<Double>,
        format: String,
        onChange: @escaping @MainActor (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(0.5)) {
            HStack {
                Text(name)
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.ink)
                Spacer()
                Text(format)
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.accent)
                    .layoutPriority(1)
            }
            MacroTunerBridge(
                value: value,
                range: range,
                accessibilityName: name,
                onChange: onChange
            )
            .frame(height: AthleticSpace.tap)
        }
        .accessibilityElement(children: .contain)
    }
}
