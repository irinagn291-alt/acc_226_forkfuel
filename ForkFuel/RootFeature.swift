import Foundation
import ComposableArchitecture

/// Root Feature reducer. Owns the `StackState` path and composes children with `Scope`.
@Reducer
struct RootFeature {
    @Reducer
    enum Path {
        case catalog(CatalogFeature)
        case detail(FuelDetailFeature)
        case assign(SlotAssignFeature)
        case planner(PlannerFeature)
        case goals(GoalsFeature)
        case wish(WishShelfFeature)
        case horizon(TrainingHorizonFeature)
        case ignition(IgnitionOnboardingFeature)
    }

    @ObservableState
    struct State {
        var ignitionComplete: Bool
        var today: TodayFeature.State
        var ignition = IgnitionOnboardingFeature.State()
        var path = StackState<Path.State>()
        var storeFailed = false
    }

    enum Action {
        case task
        case bootstrapFinished
        case bootstrapFailed
        case today(TodayFeature.Action)
        case ignition(IgnitionOnboardingFeature.Action)
        case path(StackActionOf<Path>)
        case dayRolled
        case sceneBecameActive
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.preferenceFlags) var preferenceFlags
    @Dependency(\.calendarClock) var calendarClock
    @Dependency(\.continuousClock) var clock

    var body: some Reducer<State, Action> {
        Scope(state: \.today, action: \.today) {
            TodayFeature()
        }
        Scope(state: \.ignition, action: \.ignition) {
            IgnitionOnboardingFeature()
        }
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    bootstrap(),
                    .run { send in
                        for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                            await send(.dayRolled)
                        }
                    }
                )

            case .bootstrapFinished:
                state.ignitionComplete = preferenceFlags.ignitionComplete()
                if state.ignitionComplete {
                    applyReviewScreen(&state)
                    return .send(.today(.refreshRequested))
                }
                return .none

            case .bootstrapFailed:
                state.storeFailed = true
                return .none

            case .today(.openCatalog):
                state.path.append(.catalog(CatalogFeature.State()))
                return .none

            case .today(.openPlanner):
                state.path.append(.planner(PlannerFeature.State()))
                return .none

            case .today(.openGoals):
                state.path.append(.goals(GoalsFeature.State()))
                return .none

            case .today(.openWish):
                state.path.append(.wish(WishShelfFeature.State()))
                return .none

            case .today(.openHorizon):
                state.path.append(.horizon(TrainingHorizonFeature.State()))
                return .none

            case .today:
                return .none

            case .ignition(.finished):
                state.ignitionComplete = true
                return .send(.today(.refreshRequested))

            case .ignition:
                return .none

            case let .path(.element(id: _, action: .catalog(.productPicked(product)))):
                state.path.append(.detail(FuelDetailFeature.State(product: product)))
                return .none

            case let .path(.element(id: id, action: .detail(.assignRequested))):
                guard case let .detail(detail) = state.path[id: id] else { return .none }
                let tomorrow = DayKeyCalendar.addingDays(1, to: calendarClock.dayKey(calendarClock.now()))
                state.path.append(
                    .assign(
                        SlotAssignFeature.State(
                            product: detail.product,
                            grams: detail.grams,
                            slot: FuelSlot.suggested(at: calendarClock.now()),
                            futureDay: tomorrow
                        )
                    )
                )
                return .none

            case let .path(.element(id: _, action: .assign(.committed(route)))):
                state.path.removeAll()
                switch route {
                case let .today(recordID):
                    state.today.highlightedID = recordID
                    state.today.showSuccess = true
                    return .merge(
                        .send(.today(.refreshRequested)),
                        .run { [clock] send in
                            try await clock.sleep(for: .seconds(1))
                            await send(.today(.dismissSuccess))
                        }
                    )
                case let .planner(recordID):
                    state.path.append(.planner(PlannerFeature.State(highlightID: recordID)))
                    return .send(.today(.refreshRequested))
                }

            case let .path(.element(id: _, action: .wish(.park(product, ahead)))):
                let tomorrow = DayKeyCalendar.addingDays(1, to: calendarClock.dayKey(calendarClock.now()))
                state.path.append(
                    .assign(
                        SlotAssignFeature.State(
                            product: product,
                            grams: 100,
                            slot: ahead ? .refuel : FuelSlot.suggested(at: calendarClock.now()),
                            plansAhead: ahead,
                            futureDay: tomorrow
                        )
                    )
                )
                return .none

            case .path(.element(id: _, action: .goals(.rerunIgnition))):
                state.path.append(.ignition(IgnitionOnboardingFeature.State()))
                return .none

            case .path(.element(id: _, action: .goals(.resetDone))):
                return .send(.today(.refreshRequested))

            case .path(.element(id: _, action: .ignition(.finished))):
                state.ignitionComplete = true
                _ = state.path.popLast()
                return .send(.today(.refreshRequested))

            case .path:
                return .none

            case .dayRolled, .sceneBecameActive:
                return .send(.today(.sceneBecameActive))
            }
        }
        .forEach(\.path, action: \.path)
    }

    private func applyReviewScreen(_ state: inout State) {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-ReviewScreen"), index + 1 < args.count else { return }
        switch args[index + 1] {
        case "log":
            state.path.append(.planner(PlannerFeature.State()))
        case "goals":
            state.path.append(.goals(GoalsFeature.State()))
        default:
            break
        }
    }

    private func bootstrap() -> Effect<Action> {
        .run { [fuelVault, preferenceFlags, calendarClock] send in
            do {
                try await fuelVault.bootstrapShelf()
                #if targetEnvironment(simulator)
                if preferenceFlags.consumeDemoSeed() {
                    try await fuelVault.seedDemoDay(calendarClock.dayKey(calendarClock.now()))
                    preferenceFlags.markIgnitionComplete()
                }
                #endif
                await send(.bootstrapFinished)
            } catch {
                await send(.bootstrapFailed)
            }
        }
    }
}
