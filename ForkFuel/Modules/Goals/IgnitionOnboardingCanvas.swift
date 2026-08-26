import SwiftUI
import ComposableArchitecture

@MainActor
struct IgnitionOnboardingCanvas: View {
    @Bindable var store: StoreOf<IgnitionOnboardingFeature>

    var body: some View {
        VStack(spacing: AthleticSpace.x(2)) {
            TabView(selection: Binding(
                get: { store.page },
                set: { newValue in
                    if newValue > store.page { store.send(.next) }
                    else if newValue < store.page { store.send(.back) }
                }
            )) {
                page(
                    0,
                    image: "ffl_Onboarding1",
                    title: "Fuel that matches the session",
                    body: "ForkFuel tracks energy and macros against Training and Rest targets. It is a personal food log, not medical advice."
                )
                page(
                    1,
                    image: "ffl_Onboarding2",
                    title: "Find fuel, then park it",
                    body: "Search the catalog or tap a barcode. Set grams, assign Pre-Fuel, Refuel, Recovery or a Top-Up."
                )
                page(
                    2,
                    image: "ffl_Onboarding3",
                    title: "Training-day mode",
                    body: "Tag a day as Training or Rest. Rings follow that day's budget. Pre-tag the next two weeks from Session Tags."
                )
                targetPage
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack {
                if store.page > 0 {
                    Button("Back") { store.send(.back) }
                        .font(AthleticTypeScale.body())
                        .foregroundStyle(AthleticPalette.ink)
                        .frame(minWidth: AthleticSpace.tap, minHeight: AthleticSpace.tap)
                }
                Spacer()
                Button("Skip") { store.send(.skip) }
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)
                    .frame(minHeight: AthleticSpace.tap)
                    .disabled(store.isWriting)
            }
            .padding(.horizontal, AthleticSpace.x(2))

            if store.page < 3 {
                AthleticActionButton(title: "Continue") { store.send(.next) }
                    .padding(.horizontal, AthleticSpace.x(2))
            } else {
                AthleticActionButton(
                    title: "Write targets",
                    enabled: store.training.isValid,
                    busy: store.isWriting
                ) { store.send(.finish) }
                .padding(.horizontal, AthleticSpace.x(2))
            }
        }
        .padding(.bottom, AthleticSpace.x(2))
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Ignition")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func page(_ tag: Int, image: String, title: String, body: String) -> some View {
        VStack(spacing: AthleticSpace.x(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 320)
                .accessibilityHidden(true)
            Text(title)
                .font(AthleticTypeScale.heading())
                .foregroundStyle(AthleticPalette.ink)
                .multilineTextAlignment(.center)
            Text(body)
                .font(AthleticTypeScale.body())
                .foregroundStyle(AthleticPalette.muted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AthleticSpace.x(2))
        .tag(tag)
    }

    private var targetPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                Image("ffl_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                Text("Training targets")
                    .font(AthleticTypeScale.heading())
                    .foregroundStyle(AthleticPalette.ink)
                Text("Rest targets are written as a lighter copy. Edit both later in Fuel Goals.")
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)
                slider("Energy", value: store.training.energyKcal, range: 800...8000, suffix: "kcal") {
                    store.send(.energyChanged($0))
                }
                slider("Protein", value: store.training.proteinGrams, range: 40...400, suffix: "g") {
                    store.send(.proteinChanged($0))
                }
                slider("Carbs", value: store.training.carbsGrams, range: 80...800, suffix: "g") {
                    store.send(.carbsChanged($0))
                }
                slider("Fat", value: store.training.fatGrams, range: 20...300, suffix: "g") {
                    store.send(.fatChanged($0))
                }
            }
            .padding(AthleticSpace.x(2))
        }
        .tag(3)
    }

    private func slider(_ name: String, value: Double, range: ClosedRange<Double>, suffix: String, send: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(0.5)) {
            HStack {
                Text(name)
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.ink)
                Spacer()
                Text(suffix == "kcal" ? "\(AthleticNumbers.energyKcal(value)) \(suffix)" : "\(AthleticNumbers.macroGrams(value)) \(suffix)")
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.accent)
            }
            MacroTunerBridge(value: Binding(get: { value }, set: send), range: range, accessibilityName: name)
                .frame(height: AthleticSpace.tap)
        }
    }
}
