import Foundation
import ComposableArchitecture

/// Target editor plus support actions. Persistence goes through the vault.
@Reducer
struct GoalsFeature {
    @ObservableState
    struct State: Equatable {
        var training: FuelMacroTargets = .trainingDefault
        var rest: FuelMacroTargets = .restDefault
        var warning: String?
        var isSaving: Bool = false
        var pendingReset: Bool = false
        var savedPulse: Bool = false
    }

    enum Action: Equatable {
        case task
        case loaded(FuelMacroTargets, FuelMacroTargets)
        case trainingEnergy(Double)
        case trainingProtein(Double)
        case trainingCarbs(Double)
        case trainingFat(Double)
        case restEnergy(Double)
        case restProtein(Double)
        case restCarbs(Double)
        case restFat(Double)
        case save
        case saved
        case saveFailed
        case rerunIgnition
        case askReset
        case cancelReset
        case confirmReset
        case resetDone
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.hapticPulse) var hapticPulse

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [fuelVault] send in
                    let pair = try await fuelVault.loadTargets()
                    await send(.loaded(pair.0, pair.1))
                }

            case let .loaded(training, rest):
                state.training = training
                state.rest = rest
                return .none

            case let .trainingEnergy(value):
                state.training.energyKcal = value
                return validate(&state)
            case let .trainingProtein(value):
                state.training.proteinGrams = value
                return validate(&state)
            case let .trainingCarbs(value):
                state.training.carbsGrams = value
                return validate(&state)
            case let .trainingFat(value):
                state.training.fatGrams = value
                return validate(&state)
            case let .restEnergy(value):
                state.rest.energyKcal = value
                return validate(&state)
            case let .restProtein(value):
                state.rest.proteinGrams = value
                return validate(&state)
            case let .restCarbs(value):
                state.rest.carbsGrams = value
                return validate(&state)
            case let .restFat(value):
                state.rest.fatGrams = value
                return validate(&state)

            case .save:
                guard state.training.isValid, state.rest.isValid, !state.isSaving else {
                    state.warning = "Keep energy between 800 and 8000 kcal."
                    return .none
                }
                state.isSaving = true
                let training = state.training
                let rest = state.rest
                return .run { [fuelVault] send in
                    do {
                        try await fuelVault.writeTargets(training, rest)
                        await send(.saved)
                    } catch {
                        await send(.saveFailed)
                    }
                }

            case .saved:
                state.isSaving = false
                state.savedPulse = true
                hapticPulse.commit()
                return .none

            case .saveFailed:
                state.isSaving = false
                state.warning = "Targets did not save. Retry."
                return .none

            case .rerunIgnition:
                return .none

            case .askReset:
                state.pendingReset = true
                return .none

            case .cancelReset:
                state.pendingReset = false
                return .none

            case .confirmReset:
                state.pendingReset = false
                return .run { [fuelVault] send in
                    try await fuelVault.resetAllData()
                    await send(.resetDone)
                }

            case .resetDone:
                hapticPulse.commit()
                return .send(.task)
            }
        }
    }

    private func validate(_ state: inout State) -> Effect<Action> {
        if state.training.isValid && state.rest.isValid {
            state.warning = nil
        } else {
            state.warning = "Energy must stay between 800 and 8000 kcal. Macros stay in range."
        }
        return .none
    }
}
