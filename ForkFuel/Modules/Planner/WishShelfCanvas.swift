import SwiftUI
import ComposableArchitecture

@MainActor
struct WishShelfCanvas: View {
    @Bindable var store: StoreOf<WishShelfFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                if store.loadFailed {
                    DesignedFailureBoard(
                        title: "Buy list could not load",
                        detail: "The vault did not return wished items. Retry.",
                        retryTitle: "Retry"
                    ) { store.send(.task) }
                } else if store.items.isEmpty {
                    EmptyFuelBoard(
                        asset: "ffl_EmptyWish",
                        title: "Basket is empty",
                        detail: "Save a product from its portion page. Duplicates update the existing row.",
                        actionTitle: "Reload"
                    ) { store.send(.task) }
                } else {
                    ForEach(store.items) { item in
                        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
                            FuelProductRow(product: item.product)
                            HStack {
                                Button("Eat today") { store.send(.park(item.product, false)) }
                                    .buttonStyle(WishChipStyle())
                                    .accessibilityLabel("Promote \(item.product.displayName) to eaten today")
                                Button("Plan ahead") { store.send(.park(item.product, true)) }
                                    .buttonStyle(WishChipStyle())
                                    .accessibilityLabel("Promote \(item.product.displayName) to the plan")
                                Spacer()
                                Button {
                                    store.send(.askDelete(item.id))
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(AthleticPalette.ink)
                                        .frame(width: AthleticSpace.tap, height: AthleticSpace.tap)
                                }
                                .accessibilityLabel("Remove \(item.product.displayName)")
                            }
                        }
                        .padding(AthleticSpace.x(1))
                        .background(AthleticPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                    }
                }
            }
            .padding(AthleticSpace.x(2))
        }
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Buy List")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.send(.task).finish() }
        .confirmationDialog(
            "Remove this item from the buy list?",
            isPresented: Binding(
                get: { store.pendingDelete != nil },
                set: { if !$0 { store.send(.cancelDelete) } }
            )
        ) {
            Button("Remove", role: .destructive) { store.send(.confirmDelete) }
            Button("Keep", role: .cancel) { store.send(.cancelDelete) }
        }
    }
}

@MainActor
private struct WishChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AthleticTypeScale.caption())
            .foregroundStyle(AthleticPalette.background)
            .padding(.horizontal, AthleticSpace.x(1.5))
            .frame(minHeight: AthleticSpace.tap)
            .background(AthleticPalette.accent.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
    }
}
