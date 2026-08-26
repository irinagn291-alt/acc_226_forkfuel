import Foundation
import ComposableArchitecture

/// Today session desk. Child of `RootFeature` via `Scope`.
@Reducer
struct TodayFeature {
    @ObservableState
    struct State: Equatable {
        var dayKey: Date
        var kind: TrainingDayKind = .training
        var targets: FuelMacroTargets = .trainingDefault
        var consumed: [FuelIntakeRecord] = []
        var plannedCount: Int = 0
        var highlightedID: UUID?
        var pendingDelete: UUID?
        var showSuccess: Bool = false
        var isLoading: Bool = false
        var loadFailed: Bool = false

        var aggregate: FuelIntakeAggregate {
            FuelIntakeAggregate(records: consumed)
        }

        init(dayKey: Date = Date()) {
            self.dayKey = DayKeyCalendar.key(for: dayKey)
        }
    }

    enum Action: Equatable {
        case task
        case refreshRequested
        case dayLoaded(FuelDaySnapshot)
        case loadFailed
        case openCatalog
        case openPlanner
        case openGoals
        case openWish
        case openHorizon
        case shiftDay(Int)
        case toggleKind
        case kindPersisted(TrainingDayKind)
        case askDelete(UUID)
        case confirmDelete
        case cancelDelete
        case deleted
        case sceneBecameActive
        case dismissSuccess
        case highlight(UUID?)
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.calendarClock) var calendarClock
    @Dependency(\.hapticPulse) var hapticPulse

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task, .refreshRequested, .sceneBecameActive:
                if action == .sceneBecameActive {
                    let live = calendarClock.dayKey(calendarClock.now())
                    if !DayKeyCalendar.isSameDay(live, state.dayKey) {
                        state.dayKey = live
                    }
                }
                return load(state.dayKey)

            case let .dayLoaded(snapshot):
                state.isLoading = false
                state.loadFailed = false
                state.dayKey = snapshot.dayKey
                state.kind = snapshot.kind
                state.targets = snapshot.targets
                state.consumed = snapshot.consumed
                state.plannedCount = snapshot.planned.count
                return .none

            case .loadFailed:
                state.isLoading = false
                state.loadFailed = true
                return .none

            case .openCatalog, .openPlanner, .openGoals, .openWish, .openHorizon:
                return .none

            case let .shiftDay(delta):
                state.dayKey = DayKeyCalendar.addingDays(delta, to: state.dayKey)
                state.highlightedID = nil
                return load(state.dayKey)

            case .toggleKind:
                let next: TrainingDayKind = state.kind == .training ? .rest : .training
                let day = state.dayKey
                return .run { [fuelVault] send in
                    try await fuelVault.tagDay(day, next)
                    await send(.kindPersisted(next))
                }

            case let .kindPersisted(kind):
                state.kind = kind
                hapticPulse.commit()
                return load(state.dayKey)

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
                    try await fuelVault.eraseIntake(id)
                    await send(.deleted)
                }

            case .deleted:
                return load(state.dayKey)

            case .dismissSuccess:
                state.showSuccess = false
                return .none

            case let .highlight(id):
                state.highlightedID = id
                return .none
            }
        }
    }

    private func load(_ dayKey: Date) -> Effect<Action> {
        .run { [fuelVault] send in
            do {
                let snapshot = try await fuelVault.loadDay(dayKey, TrainingDayPolicy())
                await send(.dayLoaded(snapshot))
            } catch {
                await send(.loadFailed)
            }
        }
    }
}
