import Foundation
import ComposableArchitecture

/// First-run ignition. Writes default or collected targets and the completion flag.
@Reducer
struct IgnitionOnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var page: Int = 0
        var training: FuelMacroTargets = .trainingDefault
        var isWriting: Bool = false
    }

    enum Action: Equatable {
        case next
        case back
        case skip
        case energyChanged(Double)
        case proteinChanged(Double)
        case carbsChanged(Double)
        case fatChanged(Double)
        case finish
        case finished
        case writeFailed
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.preferenceFlags) var preferenceFlags
    @Dependency(\.hapticPulse) var hapticPulse

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .next:
                state.page = min(3, state.page + 1)
                return .none
            case .back:
                state.page = max(0, state.page - 1)
                return .none
            case let .energyChanged(value):
                state.training.energyKcal = value
                return .none
            case let .proteinChanged(value):
                state.training.proteinGrams = value
                return .none
            case let .carbsChanged(value):
                state.training.carbsGrams = value
                return .none
            case let .fatChanged(value):
                state.training.fatGrams = value
                return .none
            case .skip:
                return write(training: .trainingDefault, rest: .restDefault, into: &state)
            case .finish:
                let rest = FuelMacroTargets(
                    energyKcal: (state.training.energyKcal * 0.75).rounded(),
                    proteinGrams: (state.training.proteinGrams * 0.78).rounded(),
                    carbsGrams: (state.training.carbsGrams * 0.73).rounded(),
                    fatGrams: (state.training.fatGrams * 0.81).rounded()
                )
                return write(training: state.training, rest: rest, into: &state)
            case .finished:
                state.isWriting = false
                hapticPulse.commit()
                return .none
            case .writeFailed:
                state.isWriting = false
                return .none
            }
        }
    }

    private func write(
        training: FuelMacroTargets,
        rest: FuelMacroTargets,
        into state: inout State
    ) -> Effect<Action> {
        state.isWriting = true
        return .run { [fuelVault, preferenceFlags] send in
            do {
                try await fuelVault.writeTargets(training, rest)
                preferenceFlags.markIgnitionComplete()
                await send(.finished)
            } catch {
                await send(.writeFailed)
            }
        }
    }
}
