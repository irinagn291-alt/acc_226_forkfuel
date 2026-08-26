import Foundation
import ComposableArchitecture

/// 14-day forward fuel list. Child of the root stack.
@Reducer
struct PlannerFeature {
    static let horizonDays = 14

    @ObservableState
    struct State: Equatable {
        var records: [FuelIntakeRecord] = []
        var highlightID: UUID?
        var loadFailed: Bool = false
        var pendingConsume: UUID?
    }

    enum Action: Equatable {
        case task
        case loaded([FuelIntakeRecord])
        case failed
        case askConsume(UUID)
        case confirmConsume
        case cancelConsume
        case consumed
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.calendarClock) var calendarClock
    @Dependency(\.hapticPulse) var hapticPulse

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                let start = calendarClock.dayKey(calendarClock.now())
                return .run { [fuelVault] send in
                    do {
                        let rows = try await fuelVault.plannedHorizon(start, Self.horizonDays)
                        await send(.loaded(rows))
                    } catch {
                        await send(.failed)
                    }
                }

            case let .loaded(rows):
                state.records = rows
                state.loadFailed = false
                return .none

            case .failed:
                state.loadFailed = true
                return .none

            case let .askConsume(id):
                state.pendingConsume = id
                return .none

            case .cancelConsume:
                state.pendingConsume = nil
                return .none

            case .confirmConsume:
                guard let id = state.pendingConsume else { return .none }
                state.pendingConsume = nil
                let today = calendarClock.dayKey(calendarClock.now())
                return .run { [fuelVault] send in
                    _ = try await fuelVault.markConsumed(id, today)
                    await send(.consumed)
                }

            case .consumed:
                hapticPulse.commit()
                return .send(.task)
            }
        }
    }
}
