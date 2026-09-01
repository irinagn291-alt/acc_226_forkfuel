import Foundation
import ComposableArchitecture

/// Product detail. Grams stay in the reducer; the field and steppers only report values.
@Reducer
struct FuelDetailFeature {
    @ObservableState
    struct State: Equatable {
        var product: FuelProductSnapshot
        var grams: Double = 100
        var gramText: String = "100"
        var alreadyWished: Bool = false
        var isSavingWish: Bool = false
        var gramWarning: String?

        var portion: PortionResult {
            PortionCalculator.portion(of: product, grams: grams)
        }

        var gramsAcceptable: Bool {
            PortionCalculator.isGramsAcceptable(grams)
        }
    }

    enum Action: Equatable {
        case task
        case wishStatus(Bool)
        case gramsTyped(String)
        case nudgeGrams(Int)
        case assignRequested
        case wishTapped
        case wishSettled(Bool)
        case wishFailed
    }

    @Dependency(\.fuelVault) var fuelVault
    @Dependency(\.hapticPulse) var hapticPulse

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                let code = state.product.barcode
                return .run { [fuelVault] send in
                    let saved = (try? await fuelVault.wishContains(code)) ?? false
                    await send(.wishStatus(saved))
                }

            case let .wishStatus(saved):
                state.alreadyWished = saved
                return .none

            case let .gramsTyped(text):
                state.gramText = text
                if let parsed = AthleticNumbers.parseDecimal(text), parsed > 0 {
                    applyGrams(parsed, to: &state)
                } else if text.isEmpty {
                    state.gramWarning = "Enter grams"
                } else {
                    state.gramWarning = "Use a positive number"
                }
                return .none

            case let .nudgeGrams(delta):
                applyGrams(state.grams + Double(delta), to: &state)
                state.gramText = AthleticNumbers.grams(state.grams)
                return .none

            case .assignRequested:
                return .none

            case .wishTapped:
                guard !state.alreadyWished, !state.isSavingWish else { return .none }
                state.isSavingWish = true
                let product = state.product
                return .run { [fuelVault] send in
                    do {
                        let result = try await fuelVault.upsertWish(product)
                        await send(.wishSettled(result.1))
                    } catch {
                        await send(.wishFailed)
                    }
                }

            case let .wishSettled(already):
                state.isSavingWish = false
                state.alreadyWished = true
                if !already {
                    hapticPulse.commit()
                }
                return .none

            case .wishFailed:
                state.isSavingWish = false
                return .none
            }
        }
    }

    private func applyGrams(_ value: Double, to state: inout State) {
        if value < 0 {
            state.gramWarning = "Grams cannot be negative"
            return
        }
        if !PortionCalculator.isGramsAcceptable(value) {
            state.gramWarning = "Keep grams between 1 and 2000"
            return
        }
        state.grams = value
        state.gramWarning = nil
    }
}
