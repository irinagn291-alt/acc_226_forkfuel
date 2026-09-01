import SwiftUI
import ComposableArchitecture

@MainActor
struct FuelDetailCanvas: View {
    @Bindable var store: StoreOf<FuelDetailFeature>
    @FocusState private var gramsFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                ZStack(alignment: .bottomLeading) {
                    Image("ffl_CardBackdrop")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                        .accessibilityHidden(true)
                    FuelThumbCanvas(product: store.product)
                        .frame(width: 72, height: 72)
                        .padding(AthleticSpace.x(2))
                }
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))

                Text(store.product.displayName)
                    .font(AthleticTypeScale.heading())
                    .foregroundStyle(AthleticPalette.ink)
                Text(store.product.brandMark ?? store.product.barcode)
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.muted)

                if store.product.energyIsUnknown {
                    Text("Energy is missing for this item — you can still park the grams.")
                        .font(AthleticTypeScale.body())
                        .foregroundStyle(AthleticPalette.ink)
                        .padding(AthleticSpace.x(1.5))
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
        .task { await store.send(.task).finish() }
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
            TextField("Grams", text: Binding(
                get: { store.gramText },
                set: { store.send(.gramsTyped($0)) }
            ))
            .keyboardType(.decimalPad)
            .focused($gramsFocused)
            .font(AthleticTypeScale.body())
            .foregroundStyle(AthleticPalette.ink)
            .padding(AthleticSpace.x(1.5))
            .frame(minHeight: AthleticSpace.tap)
            .background(AthleticPalette.background)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
            .accessibilityLabel("Grams")
            GramWheelBridge(grams: Binding(
                get: { store.wheelGrams },
                set: { store.send(.wheelMoved($0)) }
            ))
            .frame(height: 140)
            .accessibilityLabel("Gram wheel")
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
}
