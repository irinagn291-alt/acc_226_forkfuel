import Foundation
import ComposableArchitecture

/// Buy list. Duplicate barcodes update the existing row.
@Reducer
struct WishShelfFeature {
    @ObservableState
    struct State: Equatable {
        var items: [WishSnapshot] = []
        var loadFailed: Bool = false
        var pendingDelete: UUID?
    }

    enum Action: Equatable {
        case task
        case loaded([WishSnapshot])
        case failed
        case park(FuelProductSnapshot, Bool)
        case askDelete(UUID)
        case confirmDelete
        case cancelDelete
        case deleted
    }

    @Dependency(\.fuelVault) var fuelVault

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [fuelVault] send in
                    do {
                        await send(.loaded(try await fuelVault.wishes()))
                    } catch {
                        await send(.failed)
                    }
                }

            case let .loaded(items):
                state.items = items
                state.loadFailed = false
                return .none

            case .failed:
                state.loadFailed = true
                return .none

            case .park:
                return .none

            case let .askDelete(id):
                state.pendingDelete = id
                return .none

            case .cancelDelete:
                state.pendingDelete = nil
                return .none

            case .confirmDelete:
                guard let id = state.pendingDelete else { return .none }
                state.pendingDelete = nil
                return .run { [fuelVault] send in
                    try await fuelVault.eraseWish(id)
                    await send(.deleted)
                }

            case .deleted:
                return .send(.task)
            }
        }
    }
}
