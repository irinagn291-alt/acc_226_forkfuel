import SwiftUI

/// Shared athletic chrome. Views stay presentational; no persistence here.
@MainActor
enum AthleticChrome {
    static func textureBackdrop() -> some View {
        Image("ffl_Texture")
            .resizable(resizingMode: .tile)
            .opacity(0.07)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

@MainActor
struct AthleticActionButton: View {
    let title: String
    var enabled: Bool = true
    var busy: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(AthleticTypeScale.title())
                    .opacity(busy ? 0 : 1)
                if busy {
                    ProgressView()
                        .tint(AthleticPalette.background)
                }
            }
            .foregroundStyle(AthleticPalette.background)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AthleticSpace.tap)
            .background(enabled ? AthleticPalette.accent : AthleticPalette.muted)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        }
        .disabled(!enabled || busy)
        .accessibilityLabel(title)
    }
}

@MainActor
struct EmptyFuelBoard: View {
    let asset: String
    let title: String
    let detail: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: AthleticSpace.x(2)) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .accessibilityHidden(true)
            Text(title)
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(AthleticTypeScale.body())
                .foregroundStyle(AthleticPalette.muted)
                .multilineTextAlignment(.center)
            AthleticActionButton(title: actionTitle, action: action)
                .frame(maxWidth: 280)
        }
        .padding(AthleticSpace.x(3))
        .frame(maxWidth: .infinity)
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
    }
}

@MainActor
struct FuelThumbCanvas: View {
    let product: FuelProductSnapshot

    var body: some View {
        Group {
            if let path = product.imageRemotePath, let url = URL(string: path) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        localFallback
                    }
                }
            } else {
                localFallback
            }
        }
        .frame(width: 56, height: 56)
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var localFallback: some View {
        if let key = product.bundledAssetKey {
            Image(key)
                .resizable()
                .scaledToFill()
        } else {
            Image("ffl_ProductPlaceholder")
                .resizable()
                .scaledToFill()
        }
    }
}

@MainActor
struct FuelProductRow: View {
    let product: FuelProductSnapshot
    var highlight: Bool = false

    var body: some View {
        HStack(spacing: AthleticSpace.x(1.5)) {
            FuelThumbCanvas(product: product)
            VStack(alignment: .leading, spacing: AthleticSpace.x(0.5)) {
                Text(product.displayName)
                    .font(AthleticTypeScale.title())
                    .foregroundStyle(AthleticPalette.ink)
                    .lineLimit(1)
                Text(product.brandMark ?? product.barcode)
                    .font(AthleticTypeScale.caption())
                    .foregroundStyle(AthleticPalette.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(energyLabel)
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.accent)
                .layoutPriority(1)
        }
        .padding(AthleticSpace.x(1.5))
        .frame(minHeight: AthleticSpace.tap)
        .background(highlight ? AthleticPalette.accent.opacity(0.18) : AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.displayName), \(energyLabel) per 100 grams")
    }

    private var energyLabel: String {
        if let kcal = product.energyKcalPerHundred {
            return "\(AthleticNumbers.energyKcal(kcal)) kcal"
        }
        return "unknown"
    }
}

@MainActor
struct SlotGlyph: View {
    let slot: FuelSlot
    var size: CGFloat = 40

    var body: some View {
        Image(slot.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

@MainActor
struct MacroGlyph: View {
    let asset: String
    var size: CGFloat = 28

    var body: some View {
        Image(asset)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

@MainActor
struct DesignedFailureBoard: View {
    let title: String
    let detail: String
    let retryTitle: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1.5)) {
            Text(title)
                .font(AthleticTypeScale.title())
                .foregroundStyle(AthleticPalette.ink)
            Text(detail)
                .font(AthleticTypeScale.body())
                .foregroundStyle(AthleticPalette.muted)
            AthleticActionButton(title: retryTitle, action: retry)
        }
        .padding(AthleticSpace.x(2))
        .background(AthleticPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
    }
}
