import SwiftUI
import ComposableArchitecture

@MainActor
struct FuelDetailCanvas: View {
    @Bindable var store: StoreOf<FuelDetailFeature>
    @FocusState private var gramsFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                header
                if store.product.energyIsUnknown {
                    Text("Energy is missing for this item — you can still park the grams.")
                        .font(AthleticTypeScale.body())
                        .foregroundStyle(AthleticPalette.ink)
                        .padding(AthleticSpace.x(1.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AthleticPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                }
                perHundred
                liveTotals
                gramsBlock
                AthleticActionButton(
                    title: "Assign slot",
                    enabled: store.gramsAcceptable
                ) {
                    store.send(.assignRequested)
                }
                AthleticActionButton(
                    title: store.alreadyWished ? "Already on the buy list" : "Add to buy list",
                    enabled: !store.alreadyWished,
                    busy: store.isSavingWish
                ) {
                    store.send(.wishTapped)
                }
            }
            .padding(AthleticSpace.x(2))
        }
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture { gramsFocused = false }
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Portion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AthleticPalette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await store.send(.task).finish() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AthleticSpace.x(1.5)) {
            FuelThumbCanvas(product: store.product)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: AthleticSpace.x(0.5)) {
                Text(store.product.displayName)
                    .font(AthleticTypeScale.heading())
                    .foregroundStyle(AthleticPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(store.product.brandMark ?? store.product.barcode)
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AthleticSpace.x(1.5))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.product.displayName), \(store.product.brandMark ?? store.product.barcode)")
    }

    private var perHundred: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Text("Per 100 g")
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            macroLine("Energy", AthleticNumbers.energyKcal(store.product.energyKcalPerHundred), unit: "kcal")
            macroLine("Protein", AthleticNumbers.macroGrams(store.product.proteinPerHundred), unit: "g")
            macroLine("Carbs", AthleticNumbers.macroGrams(store.product.carbsPerHundred), unit: "g")
            macroLine("Fat", AthleticNumbers.macroGrams(store.product.fatPerHundred), unit: "g")
            if let off = FuelCitationCatalog.entries.first(where: { $0.url.host == "world.openfoodfacts.org" }) {
                Link("Open Food Facts source", destination: off.url)
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.accent)
                    .frame(minHeight: AthleticSpace.tap)
                    .accessibilityLabel("Open Food Facts source")
            }
        }
        .padding(AthleticSpace.x(1.5))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
    }

    private var liveTotals: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Text("This portion")
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            macroLine("Energy", AthleticNumbers.energyKcal(store.portion.energyKcal), unit: "kcal")
            macroLine("Protein", AthleticNumbers.macroGrams(store.portion.proteinGrams), unit: "g")
            macroLine("Carbs", AthleticNumbers.macroGrams(store.portion.carbsGrams), unit: "g")
            macroLine("Fat", AthleticNumbers.macroGrams(store.portion.fatGrams), unit: "g")
        }
        .padding(AthleticSpace.x(1.5))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
    }

    private func macroLine(_ title: String, _ value: String, unit: String) -> some View {
        HStack {
            Text(title)
                .font(AthleticTypeScale.body())
                .foregroundStyle(AthleticPalette.ink)
            Spacer()
            Text(value == "—" ? "unknown" : "\(value) \(unit)")
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.accent)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value == "—" ? "unknown" : value)")
    }

    private var gramsBlock: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Text("Grams")
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            HStack(spacing: AthleticSpace.x(1)) {
                gramStep(title: "−", label: "Minus 10 grams") {
                    store.send(.nudgeGrams(-10))
                }
                TextField("Grams", text: Binding(
                    get: { store.gramText },
                    set: { store.send(.gramsTyped($0)) }
                ))
                .keyboardType(.decimalPad)
                .focused($gramsFocused)
                .multilineTextAlignment(.center)
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
                .padding(.horizontal, AthleticSpace.x(1))
                .frame(minHeight: AthleticSpace.tap)
                .background(AthleticPalette.background)
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                .accessibilityLabel("Grams")
                gramStep(title: "+", label: "Plus 10 grams") {
                    store.send(.nudgeGrams(10))
                }
            }
            if let warning = store.gramWarning {
                Text(warning)
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.ink)
            }
        }
        .padding(AthleticSpace.x(1.5))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
    }

    private func gramStep(title: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.background)
                .frame(width: AthleticSpace.tap, height: AthleticSpace.tap)
                .background(AthleticPalette.accent)
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        }
        .accessibilityLabel(label)
    }
}
