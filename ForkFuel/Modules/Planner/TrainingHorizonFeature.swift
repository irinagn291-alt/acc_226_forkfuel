import Foundation
import ComposableArchitecture

/// Twist screen: pre-tag upcoming days as Training or Rest.
@Reducer
struct TrainingHorizonFeature {
    static let horizonDays = 14

    struct HorizonDay: Equatable, Sendable, Identifiable {
        var dayKey: Date
        var kind: TrainingDayKind
        var id: Date { dayKey }
    }

    @ObservableState
    struct State: Equatable {
        var days: [HorizonDay] = []
        var loadFailed: Bool = false
    }

    enum Action: Equatable {
        case task
        case loaded([HorizonDay])
        case failed
        case toggle(Date)
        case persisted
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.calendarClock) var calendarClock
    @Dependency(\.hapticPulse) var hapticPulse

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                let start = calendarClock.dayKey(calendarClock.now())
                let policy = TrainingDayPolicy()
                return .run { [fuelVault] send in
                    do {
                        let tags = try await fuelVault.tags(start, Self.horizonDays)
                        let days = (0..<Self.horizonDays).map { offset -> HorizonDay in
                            let key = DayKeyCalendar.addingDays(offset, to: start)
                            let kind = policy.resolvedKind(stored: tags[key], dayKey: key)
                            return HorizonDay(dayKey: key, kind: kind)
                        }
                        await send(.loaded(days))
                    } catch {
                        await send(.failed)
                    }
                }

            case let .loaded(days):
                state.days = days
                state.loadFailed = false
                return .none

            case .failed:
                state.loadFailed = true
                return .none

            case let .toggle(dayKey):
                guard let index = state.days.firstIndex(where: { $0.dayKey == dayKey }) else { return .none }
                let next: TrainingDayKind = state.days[index].kind == .training ? .rest : .training
                state.days[index].kind = next
                return .run { [fuelVault] send in
                    try await fuelVault.tagDay(dayKey, next)
                    await send(.persisted)
                }

            case .persisted:
                hapticPulse.commit()
                return .none
            }
        }
    }
}
