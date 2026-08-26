import SwiftUI
import ComposableArchitecture

@MainActor
struct SlotAssignCanvas: View {
    @Bindable var store: StoreOf<SlotAssignFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                Text(store.product.displayName)
                    .font(AthleticTypeScale.heading())
                    .foregroundStyle(AthleticPalette.ink)
                Text("\(AthleticNumbers.grams(store.grams)) g")
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)

                Text("Slot")
                    .font(AthleticTypeScale.title())
                    .foregroundStyle(AthleticPalette.ink)
                ForEach(FuelSlot.allCases) { slot in
                    let blocked = store.plansAhead && slot == .topUp
                    Button {
                        store.send(.slotPicked(slot))
                    } label: {
                        HStack(spacing: AthleticSpace.x(1.5)) {
                            SlotGlyph(slot: slot)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(slot.title)
                                    .font(AthleticTypeScale.title())
                                    .foregroundStyle(AthleticPalette.ink)
                                Text(blocked ? "Top-Up remaps to Refuel when planned" : slot.canPlanAhead ? "Can be planned" : "Eaten only")
                                    .font(AthleticTypeScale.caption())
                                    .foregroundStyle(AthleticPalette.muted)
                            }
                            Spacer()
                            if store.effectiveSlot == slot {
                                Image("ffl_ControlFace")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(AthleticSpace.x(1.5))
                        .frame(minHeight: AthleticSpace.tap)
                        .background(store.effectiveSlot == slot ? AthleticPalette.accent.opacity(0.16) : AthleticPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                    }
                    .disabled(blocked)
                    .accessibilityLabel(slot.title)
                    .accessibilityValue(store.effectiveSlot == slot ? "Selected" : "Not selected")
                }

                Toggle(isOn: Binding(
                    get: { store.plansAhead },
                    set: { store.send(.plansAheadChanged($0)) }
                )) {
                    Text("Park on a future day")
                        .font(AthleticTypeScale.body())
                        .foregroundStyle(AthleticPalette.ink)
                }
                .tint(AthleticPalette.accent)
                .padding(AthleticSpace.x(1.5))
                .frame(minHeight: AthleticSpace.tap)
                .background(AthleticPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))

                if store.plansAhead {
                    DatePicker(
                        "Future day",
                        selection: Binding(
                            get: { store.futureDay },
                            set: { store.send(.futureDayChanged($0)) }
                        ),
                        in: Date.now...,
                        displayedComponents: .date
                    )
                    .font(AthleticTypeScale.body())
                    .tint(AthleticPalette.accent)
                    .padding(AthleticSpace.x(1.5))
                    .background(AthleticPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                    .accessibilityLabel("Future day")
                }

                AthleticActionButton(title: "Confirm", busy: store.isCommitting) {
                    store.send(.confirm)
                }
            }
            .padding(AthleticSpace.x(2))
        }
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Park the Fuel")
        .navigationBarTitleDisplayMode(.inline)
    }
}
