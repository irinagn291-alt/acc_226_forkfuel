import SwiftUI
import ComposableArchitecture

@MainActor
struct PlannerCanvas: View {
    @Bindable var store: StoreOf<PlannerFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                Text("Next 14 days")
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.muted)
                if store.loadFailed {
                    DesignedFailureBoard(
                        title: "Forward fuel could not load",
                        detail: "The vault did not return the horizon. Retry.",
                        retryTitle: "Retry"
                    ) { store.send(.task) }
                } else if store.records.isEmpty {
                    EmptyFuelBoard(
                        asset: "ffl_EmptyPlan",
                        title: "Horizon is clear",
                        detail: "Nothing is parked in the next 14 days. Assign a future slot from the catalog.",
                        actionTitle: "Reload"
                    ) { store.send(.task) }
                } else {
                    ForEach(store.records) { record in
                        HStack(spacing: AthleticSpace.x(1.5)) {
                            FuelThumbCanvas(product: record.product)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.product.displayName)
                                    .font(AthleticTypeScale.body())
                                    .foregroundStyle(AthleticPalette.ink)
                                    .lineLimit(1)
                                Text("\(record.slot.title) · \(record.dayKey.formatted(date: .abbreviated, time: .omitted))")
                                    .font(AthleticTypeScale.caption())
                                    .foregroundStyle(AthleticPalette.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Button("Eat now") {
                                store.send(.askConsume(record.id))
                            }
                            .font(AthleticTypeScale.caption())
                            .foregroundStyle(AthleticPalette.background)
                            .padding(.horizontal, AthleticSpace.x(1.5))
                            .frame(minHeight: AthleticSpace.tap)
                            .background(AthleticPalette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                            .accessibilityLabel("Convert \(record.product.displayName) to eaten today")
                        }
                        .padding(AthleticSpace.x(1.5))
                        .background(record.id == store.highlightID ? AthleticPalette.accent.opacity(0.18) : AthleticPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                    }
                }
            }
            .padding(AthleticSpace.x(2))
        }
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Forward Fuel")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.send(.task).finish() }
        .confirmationDialog(
            "Move this item to today's eaten log?",
            isPresented: Binding(
                get: { store.pendingConsume != nil },
                set: { if !$0 { store.send(.cancelConsume) } }
            )
        ) {
            Button("Eat now") { store.send(.confirmConsume) }
            Button("Keep planned", role: .cancel) { store.send(.cancelConsume) }
        }
    }
}
