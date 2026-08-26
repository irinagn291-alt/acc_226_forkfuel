import Foundation
import ComposableArchitecture

/// Search + scan catalog. Child of the root stack.
@Reducer
struct CatalogFeature {
    enum Segment: Equatable, Sendable {
        case search
        case scan
    }

    enum Phase: Equatable, Sendable {
        case idle
        case pending
        case results
        case empty
        case transport
    }

    enum ResolveNotice: Equatable, Sendable {
        case notFound
        case transport
    }

    @ObservableState
    struct State: Equatable {
        var segment: Segment = .search
        var query: String = ""
        var results: [FuelProductSnapshot] = []
        var phase: Phase = .idle
        var showSpinner: Bool = false
        var access: CaptureAccess = .unknown
        var scannerRunning: Bool = false
        var manualCode: String = ""
        var resolveNotice: ResolveNotice?
        var resolving: Bool = false
        var sceneActive: Bool = true
    }

    enum Action: Equatable {
        case segmentChanged(Segment)
        case queryChanged(String)
        case searchDebounced
        case revealSpinner
        case searchSettled([FuelProductSnapshot])
        case searchFailed
        case productPicked(FuelProductSnapshot)
        case scanAppeared
        case scanDisappeared
        case accessResolved(CaptureAccess)
        case payloadCaptured(String)
        case manualCodeChanged(String)
        case submitManual
        case pickSample(String)
        case resolveSettled(Result<FuelProductSnapshot, NutritionFailure>)
        case dismissNotice
        case openSettings
        case sceneActiveChanged(Bool)
    }

    enum CancelID { case search, resolve }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.nutritionGateway) var nutritionGateway
    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.settingsJump) var settingsJump

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .segmentChanged(segment):
                state.segment = segment
                if segment == .scan {
                    return .send(.scanAppeared)
                }
                return .send(.scanDisappeared)

            case let .queryChanged(text):
                state.query = text
                return .run { [clock] send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.searchDebounced)
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .searchDebounced:
                let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                if query.isEmpty {
                    state.phase = .idle
                    state.results = []
                    state.showSpinner = false
                    return .none
                }
                state.phase = .pending
                state.showSpinner = false
                return .merge(
                    .run { [clock] send in
                        try await clock.sleep(for: .milliseconds(150))
                        await send(.revealSpinner)
                    }
                    .cancellable(id: CancelID.search, cancelInFlight: false),
                    .run { [nutritionGateway] send in
                        do {
                            let rows = try await nutritionGateway.searchFuel(query)
                            await send(.searchSettled(rows))
                        } catch is CancellationError {
                            return
                        } catch NutritionFailure.cancelled {
                            return
                        } catch {
                            await send(.searchFailed)
                        }
                    }
                    .cancellable(id: CancelID.search, cancelInFlight: true)
                )

            case .revealSpinner:
                if state.phase == .pending {
                    state.showSpinner = true
                }
                return .none

            case let .searchSettled(rows):
                state.showSpinner = false
                state.results = rows
                state.phase = rows.isEmpty ? .empty : .results
                return .none

            case .searchFailed:
                state.showSpinner = false
                state.results = FuelShelfCatalog.matches(terms: state.query)
                state.phase = state.results.isEmpty ? .transport : .results
                return .none

            case .productPicked:
                return .none

            case .scanAppeared:
                state.segment = .scan
                return .run { send in
                    var access = CaptureProbe.current()
                    await send(.accessResolved(access))
                    if access == .notDetermined {
                        let granted = await CaptureProbe.request()
                        access = granted ? .authorized : CaptureProbe.current()
                        await send(.accessResolved(access))
                    }
                }

            case .scanDisappeared:
                state.scannerRunning = false
                return .none

            case let .accessResolved(access):
                state.access = access
                state.scannerRunning = access == .authorized && state.sceneActive && state.segment == .scan
                return .none

            case let .sceneActiveChanged(active):
                state.sceneActive = active
                if !active {
                    state.scannerRunning = false
                } else if state.segment == .scan, state.access == .authorized {
                    state.scannerRunning = true
                }
                return .none

            case let .manualCodeChanged(text):
                state.manualCode = text
                return .none

            case let .payloadCaptured(raw):
                return resolve(raw, into: &state)

            case .submitManual:
                return resolve(state.manualCode, into: &state)

            case let .pickSample(code):
                state.manualCode = code
                return resolve(code, into: &state)

            case let .resolveSettled(.success(product)):
                state.resolving = false
                state.resolveNotice = nil
                return .send(.productPicked(product))

            case let .resolveSettled(.failure(failure)):
                state.resolving = false
                switch failure {
                case .notFound:
                    state.resolveNotice = .notFound
                case .cancelled:
                    break
                default:
                    state.resolveNotice = .transport
                }
                return .none

            case .dismissNotice:
                state.resolveNotice = nil
                return .none

            case .openSettings:
                return .run { [settingsJump] _ in
                    await settingsJump.open()
                }
            }
        }
    }

    private func resolve(_ raw: String, into state: inout State) -> Effect<Action> {
        let codes = BarcodeNormaliser.candidates(from: raw)
        guard !codes.isEmpty else {
            state.resolveNotice = .notFound
            return .none
        }
        state.resolving = true
        state.resolveNotice = nil
        return .run { [nutritionGateway, fuelVault] send in
            do {
                let product = try await CatalogFeature.lookup(codes: codes, gateway: nutritionGateway, vault: fuelVault)
                await send(.resolveSettled(.success(product)))
            } catch let failure as NutritionFailure {
                await send(.resolveSettled(.failure(failure)))
            } catch {
                await send(.resolveSettled(.failure(.transport)))
            }
        }
        .cancellable(id: CancelID.resolve, cancelInFlight: true)
    }

    static func lookup(
        codes: [String],
        gateway: NutritionGateway,
        vault: FuelVaultClient
    ) async throws -> FuelProductSnapshot {
        for code in codes {
            if let cached = try await vault.product(code) {
                return cached
            }
        }
        var transportSeen = false
        for code in codes {
            do {
                let remote = try await gateway.fetchProduct(code)
                try await vault.cacheProduct(remote)
                return remote
            } catch NutritionFailure.notFound {
                continue
            } catch NutritionFailure.cancelled {
                throw NutritionFailure.cancelled
            } catch {
                transportSeen = true
            }
        }
        for code in codes {
            if let shelf = FuelShelfCatalog.item(barcode: code) {
                try await vault.cacheProduct(shelf)
                return shelf
            }
        }
        throw transportSeen ? NutritionFailure.transport : NutritionFailure.notFound
    }
}
