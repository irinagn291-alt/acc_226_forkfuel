import SwiftUI

/// Native slider. Reports live values back to the feature.
struct MacroTunerBridge: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var accessibilityName: String

    var body: some View {
        Slider(value: $value, in: range)
            .tint(Color("ffl_accent"))
            .accessibilityLabel(accessibilityName)
            .accessibilityValue(AthleticNumbers.macroGrams(value))
    }
}
