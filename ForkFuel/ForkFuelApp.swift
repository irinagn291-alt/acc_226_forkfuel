import SwiftUI
import SwiftData
import ComposableArchitecture
@preconcurrency import Alamofire

@main
struct ForkFuelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                AthleticPalette.background
                    .ignoresSafeArea()
                    .overlay { ProgressView() }
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                RootHost()
            }
        }
    }

    private func performRegistration() {
        let pushToken = ""
        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }
        Alamofire.NetworkService.shared.performRegistration(pushToken: pushToken) { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}

/// Creates one `ModelContainer` at launch and injects it as a TCA dependency.
@MainActor
struct RootHost: View {
    @State private var store: StoreOf<RootFeature>?
    @State private var failed = false

    var body: some View {
        Group {
            if let store {
                RootCanvas(store: store)
            } else if failed {
                LaunchRecoveryCanvas(retry: bootstrap)
            } else {
                AthleticPalette.background
                    .ignoresSafeArea()
                    .onAppear(perform: bootstrap)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func bootstrap() {
        switch FuelStoreBootstrap.makeContainer() {
        case let .success(container):
            let vault = FuelVaultClient.live(container: container)
            let flags = PreferenceFlagClientKey.liveValue
            store = Store(
                initialState: RootFeature.State(
                    ignitionComplete: flags.ignitionComplete(),
                    today: TodayFeature.State()
                )
            ) {
                RootFeature()
            } withDependencies: {
                $0.fuelVault = vault
                $0.preferenceFlags = flags
            }
            failed = false
        case .failure:
            failed = true
        }
    }
}
