import SwiftUI
import ComposableArchitecture

@MainActor
struct TrainingHorizonCanvas: View {
    let store: StoreOf<TrainingHorizonFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AthleticSpace.x(2)) {
                Image("ffl_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                Text("Training-day mode")
                    .font(AthleticTypeScale.heading())
                    .foregroundStyle(AthleticPalette.ink)
                Text("Tag each of the next 14 days as Training or Rest. Today's rings use that day's target set.")
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)
                if store.loadFailed {
                    DesignedFailureBoard(
                        title: "Tags could not load",
                        detail: "The vault did not return session tags. Retry.",
                        retryTitle: "Retry"
                    ) { store.send(.task) }
                } else {
                    ForEach(store.days) { day in
                        Button {
                            store.send(.toggle(day.dayKey))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(day.dayKey, style: .date)
                                        .font(AthleticTypeScale.title())
                                        .foregroundStyle(AthleticPalette.ink)
                                    Text(day.kind.subtitle)
                                        .font(AthleticTypeScale.caption())
                                        .foregroundStyle(AthleticPalette.muted)
                                }
                                Spacer()
                                Text(day.kind.title)
                                    .font(AthleticTypeScale.title())
                                    .foregroundStyle(day.kind == .training ? AthleticPalette.background : AthleticPalette.ink)
                                    .padding(.horizontal, AthleticSpace.x(1.5))
                                    .frame(minHeight: AthleticSpace.tap)
                                    .background(day.kind == .training ? AthleticPalette.accent : AthleticPalette.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                            }
                            .padding(AthleticSpace.x(1.5))
                            .background(AthleticPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                        }
                        .accessibilityLabel("\(day.dayKey.formatted(date: .abbreviated, time: .omitted)), \(day.kind.title)")
                        .accessibilityHint("Switches Training and Rest")
                    }
                }
            }
            .padding(AthleticSpace.x(2))
        }
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Session Tags")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.send(.task).finish() }
    }
}
