import Foundation
import ComposableArchitecture

/// Slot + date assignment. Snack remapping lives in the reducer, not the view.
@Reducer
struct SlotAssignFeature {
    enum CommitRoute: Equatable, Sendable {
        case today(UUID)
        case planner(UUID)
    }

    @ObservableState
    struct State: Equatable {
        var product: FuelProductSnapshot
        var grams: Double
        var slot: FuelSlot
        var plansAhead: Bool = false
        var futureDay: Date
        var isCommitting: Bool = false
        var policy = TrainingDayPolicy()

        var effectiveSlot: FuelSlot {
            policy.slotForPlanning(slot, plansAhead: plansAhead)
        }
    }

    enum Action: Equatable {
        case slotPicked(FuelSlot)
        case plansAheadChanged(Bool)
        case futureDayChanged(Date)
        case confirm
        case committed(CommitRoute)
        case commitFailed
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.calendarClock) var calendarClock
    @Dependency(\.hapticPulse) var hapticPulse

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .slotPicked(slot):
                if state.plansAhead && slot == .topUp {
                    state.slot = state.policy.slotForPlanning(slot, plansAhead: true)
                } else {
                    state.slot = slot
                }
                return .none

            case let .plansAheadChanged(ahead):
                state.plansAhead = ahead
                if ahead {
                    state.slot = state.policy.slotForPlanning(state.slot, plansAhead: true)
                }
                return .none

            case let .futureDayChanged(date):
                let key = calendarClock.dayKey(date)
                let today = calendarClock.dayKey(calendarClock.now())
                state.futureDay = key
                if key > today {
                    state.plansAhead = true
                    state.slot = state.policy.slotForPlanning(state.slot, plansAhead: true)
                }
                return .none

            case .confirm:
                guard !state.isCommitting else { return .none }
                state.isCommitting = true
                let today = calendarClock.dayKey(calendarClock.now())
                let day = state.plansAhead ? state.futureDay : today
                let slot = state.policy.slotForPlanning(state.slot, plansAhead: state.plansAhead && day > today)
                let draft = FuelIntakeDraft(
                    product: state.product,
                    grams: state.grams,
                    slot: slot,
                    dayKey: day,
                    isConsumed: !state.plansAhead
                )
                let eaten = !state.plansAhead
                return .run { [fuelVault] send in
                    do {
                        let record = try await fuelVault.persistIntake(draft)
                        await send(.committed(eaten ? .today(record.id) : .planner(record.id)))
                    } catch {
                        await send(.commitFailed)
                    }
                }

            case .committed:
                hapticPulse.commit()
                state.isCommitting = false
                return .none

            case .commitFailed:
                state.isCommitting = false
                return .none
            }
        }
    }
}
