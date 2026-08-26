import SwiftUI
import ComposableArchitecture

/// Catalog with inner Search / Scan segments. No tabs at the app level.
@MainActor
struct CatalogCanvas: View {
    @Bindable var store: StoreOf<CatalogFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: AthleticSpace.x(2)) {
            Picker("Catalog mode", selection: Binding(
                get: { store.segment },
                set: { store.send(.segmentChanged($0)) }
            )) {
                Text("Search").tag(CatalogFeature.Segment.search)
                Text("Scan").tag(CatalogFeature.Segment.scan)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AthleticSpace.x(2))

            if store.segment == .search {
                searchPane
            } else {
                scanPane
            }
        }
        .padding(.top, AthleticSpace.x(1))
        .background(AthleticPalette.background.ignoresSafeArea())
        .navigationTitle("Fuel Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in
            store.send(.sceneActiveChanged(phase == .active))
        }
        .onDisappear { store.send(.scanDisappeared) }
    }

    private var searchPane: some View {
        VStack(spacing: AthleticSpace.x(2)) {
            TextField("Search the catalog", text: Binding(
                get: { store.query },
                set: { store.send(.queryChanged($0)) }
            ))
            .font(AthleticTypeScale.body())
            .foregroundStyle(AthleticPalette.ink)
            .padding(AthleticSpace.x(1.5))
            .frame(minHeight: AthleticSpace.tap)
            .background(AthleticPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
            .padding(.horizontal, AthleticSpace.x(2))
            .accessibilityLabel("Search the catalog")

            if store.showSpinner {
                ProgressView()
                    .tint(AthleticPalette.accent)
                    .frame(height: 36)
            }

            switch store.phase {
            case .idle:
                Text("Type a name. Shelf items stay available offline.")
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)
                    .padding(.horizontal, AthleticSpace.x(2))
                shelfChips
            case .pending:
                Color.clear.frame(height: 36)
            case .results:
                resultList
            case .empty:
                EmptyFuelBoard(
                    asset: "ffl_EmptySearch",
                    title: "No match on the track",
                    detail: "The catalog and the local shelf both came back empty. Try another name.",
                    actionTitle: "Clear search"
                ) { store.send(.queryChanged("")) }
                .padding(.horizontal, AthleticSpace.x(2))
            case .transport:
                DesignedFailureBoard(
                    title: "Catalog is out of reach",
                    detail: "The network dropped before any shelf match. Retry when you have a signal.",
                    retryTitle: "Retry",
                    retry: { store.send(.searchDebounced) }
                )
                .padding(.horizontal, AthleticSpace.x(2))
            }
            Spacer(minLength: 0)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: AthleticSpace.x(1)) {
                ForEach(store.results) { product in
                    Button {
                        store.send(.productPicked(product))
                    } label: {
                        FuelProductRow(product: product)
                    }
                    .accessibilityLabel(product.displayName)
                }
            }
            .padding(.horizontal, AthleticSpace.x(2))
        }
    }

    private var shelfChips: some View {
        ScrollView {
            LazyVStack(spacing: AthleticSpace.x(1)) {
                ForEach(FuelShelfCatalog.items) { product in
                    Button {
                        store.send(.productPicked(product))
                    } label: {
                        FuelProductRow(product: product)
                    }
                }
            }
            .padding(.horizontal, AthleticSpace.x(2))
        }
    }

    private var scanPane: some View {
        ScrollView {
            VStack(spacing: AthleticSpace.x(2)) {
                scanSurface
                manualField
                sampleChips
                if store.resolving {
                    ProgressView()
                        .tint(AthleticPalette.accent)
                        .frame(height: 36)
                }
                if let notice = store.resolveNotice {
                    DesignedFailureBoard(
                        title: notice == .notFound ? "That code is not in the catalog" : "Lookup lost the signal",
                        detail: notice == .notFound
                            ? "Open Food Facts has no product for this barcode. Type another code or pick a shelf item."
                            : "The product is not cached and the network failed. Retry or use a shelf barcode.",
                        retryTitle: "Dismiss",
                        retry: { store.send(.dismissNotice) }
                    )
                }
            }
            .padding(.horizontal, AthleticSpace.x(2))
            .padding(.bottom, AthleticSpace.x(3))
        }
        .scrollDismissesKeyboard(.immediately)
    }

    @ViewBuilder
    private var scanSurface: some View {
        switch store.access {
        case .unknown, .notDetermined:
            Color.clear
                .frame(height: 240)
                .background(AthleticPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        case .missingDevice:
            VStack(spacing: AthleticSpace.x(1.5)) {
                Image("ffl_Onboarding2")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .accessibilityHidden(true)
                Text("No capture device")
                    .font(AthleticTypeScale.title())
                    .foregroundStyle(AthleticPalette.ink)
                Text("This machine has no camera. Type a barcode or tap a shelf sample.")
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(AthleticSpace.x(2))
            .frame(maxWidth: .infinity)
            .background(AthleticPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: AthleticSpace.x(1.5)) {
                Text(store.access == .restricted ? "Camera is restricted" : "Camera is blocked")
                    .font(AthleticTypeScale.title())
                    .foregroundStyle(AthleticPalette.ink)
                Text("ForkFuel reads barcodes to load food into your training-day plan. Open Settings to allow the camera, or type a code.")
                    .font(AthleticTypeScale.body())
                    .foregroundStyle(AthleticPalette.muted)
                AthleticActionButton(title: "Open Settings") {
                    store.send(.openSettings)
                }
            }
            .padding(AthleticSpace.x(2))
            .background(AthleticPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
        case .authorized:
            ZStack {
                BarcodeScannerBridge(
                    isRunning: store.scannerRunning,
                    onPayload: { store.send(.payloadCaptured($0)) }
                )
                Image("ffl_ScanOverlay")
                    .resizable()
                    .scaledToFit()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
            .accessibilityLabel("Barcode scanner. Tap a recognised code.")
        }
    }

    private var manualField: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Text("Manual code")
                .font(AthleticTypeScale.caption())
                .foregroundStyle(AthleticPalette.muted)
            TextField("Paste a barcode or product URL", text: Binding(
                get: { store.manualCode },
                set: { store.send(.manualCodeChanged($0)) }
            ))
            .keyboardType(.numbersAndPunctuation)
            .textInputAutocapitalization(.never)
            .font(AthleticTypeScale.body())
            .foregroundStyle(AthleticPalette.ink)
            .padding(AthleticSpace.x(1.5))
            .frame(minHeight: AthleticSpace.tap)
            .background(AthleticPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
            .accessibilityLabel("Manual barcode")
            AthleticActionButton(title: "Resolve code", enabled: !store.manualCode.isEmpty, busy: store.resolving) {
                store.send(.submitManual)
            }
        }
    }

    private var sampleChips: some View {
        VStack(alignment: .leading, spacing: AthleticSpace.x(1)) {
            Text("Shelf samples")
                .font(AthleticTypeScale.caption())
                .foregroundStyle(AthleticPalette.muted)
            ForEach(FuelShelfCatalog.items) { product in
                Button {
                    store.send(.pickSample(product.barcode))
                } label: {
                    HStack {
                        Text(product.displayName)
                            .font(AthleticTypeScale.body())
                            .foregroundStyle(AthleticPalette.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(product.barcode)
                            .font(AthleticTypeScale.caption())
                            .foregroundStyle(AthleticPalette.accent)
                            .layoutPriority(1)
                    }
                    .padding(AthleticSpace.x(1.5))
                    .frame(minHeight: AthleticSpace.tap)
                    .background(AthleticPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AthleticSpace.corner, style: .continuous))
                }
                .accessibilityLabel("Sample \(product.displayName)")
            }
        }
    }
}
