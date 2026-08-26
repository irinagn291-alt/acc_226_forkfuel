import SwiftUI
import ComposableArchitecture

/// Single `NavigationStack` driven by `StackState`. No tabs. No modal primary flow.
@MainActor
struct RootCanvas: View {
    @Bindable var store: StoreOf<RootFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.storeFailed {
                LaunchRecoveryCanvas(retry: { store.send(.task) })
            } else if !store.ignitionComplete {
                IgnitionOnboardingCanvas(store: store.scope(state: \.ignition, action: \.ignition))
            } else {
                NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                    TodayCanvas(store: store.scope(state: \.today, action: \.today))
                } destination: { store in
                    switch store.case {
                    case let .catalog(store):
                        CatalogCanvas(store: store)
                    case let .detail(store):
                        FuelDetailCanvas(store: store)
                    case let .assign(store):
                        SlotAssignCanvas(store: store)
                    case let .planner(store):
                        PlannerCanvas(store: store)
                    case let .goals(store):
                        GoalsCanvas(store: store)
                    case let .wish(store):
                        WishShelfCanvas(store: store)
                    case let .horizon(store):
                        TrainingHorizonCanvas(store: store)
                    case let .ignition(store):
                        IgnitionOnboardingCanvas(store: store)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AthleticPalette.accent)
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.send(.sceneBecameActive)
            }
        }
    }
}

@MainActor
struct LaunchRecoveryCanvas: View {
    var retry: () -> Void

    var body: some View {
        VStack(spacing: AthleticSpace.x(2)) {
            Image("ffl_EmptyLog")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .accessibilityHidden(true)
            Text("The vault did not open")
                .font(AthleticTypeScale.heading())
                .foregroundStyle(AthleticPalette.ink)
            Text("ForkFuel could not create its on-device store. Retry, or delete the app data if the file is damaged.")
                .font(AthleticTypeScale.body())
                .foregroundStyle(AthleticPalette.muted)
                .multilineTextAlignment(.center)
            AthleticActionButton(title: "Retry", action: retry)
        }
        .padding(AthleticSpace.x(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AthleticPalette.background.ignoresSafeArea())
    }
}
