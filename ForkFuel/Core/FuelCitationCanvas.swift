import SwiftUI

/// Tappable source list. Shown on Today, Fuel Goals and Ignition so citations stay easy to find.
@MainActor
struct FuelCitationBoard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1.5)) {
            Text("Sources")
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            Text("ForkFuel is a personal food log, not medical advice. Starting Training and Rest budgets follow these public references. You can edit every number in Fuel Goals.")
                .font(AthleticTypeScale.caption())
                .foregroundStyle(AthleticPalette.muted)
            ForEach(FuelCitationCatalog.entries) { entry in
                Link(destination: entry.url) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(AthleticTypeScale.body())
                            .foregroundStyle(AthleticPalette.accent)
                            .multilineTextAlignment(.leading)
                        Text(entry.detail)
                            .font(AthleticTypeScale.caption())
                            .foregroundStyle(AthleticPalette.muted)
                            .multilineTextAlignment(.leading)
                        Text(entry.url.host ?? entry.url.absoluteString)
                            .font(AthleticTypeScale.micro())
                            .foregroundStyle(AthleticPalette.ink)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AthleticSpace.x(1.5))
                    .frame(minHeight: AthleticSpace.tap)
                    .background(AthleticPalette.background)
                    .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                }
                .accessibilityLabel("\(entry.title). Opens source link.")
            }
        }
        .padding(AthleticSpace.x(2))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sources for fuel targets and food data")
    }
}

/// Full-screen sources desk used from a sheet.
@MainActor
struct FuelCitationCanvas: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                FuelCitationBoard()
                    .padding(AthleticSpace.x(2))
            }
            .background(AthleticPalette.background.ignoresSafeArea())
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .tint(AthleticPalette.accent)
    }
}
