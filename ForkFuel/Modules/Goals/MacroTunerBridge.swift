import SwiftUI
import UIKit

/// Native slider. Coordinator stays on the main actor so UISlider.value is legal under Swift 6.
@MainActor
struct MacroTunerBridge: UIViewRepresentable {
    var value: Double
    var range: ClosedRange<Double>
    var accessibilityName: String
    var onChange: @MainActor (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.tintColor = UIColor(named: "ffl_accent")
        slider.accessibilityLabel = accessibilityName
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        context.coordinator.onChange = onChange
        return slider
    }

    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.onChange = onChange
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        if abs(Double(slider.value) - value) > 0.05 {
            slider.value = Float(value)
        }
        slider.accessibilityLabel = accessibilityName
        slider.accessibilityValue = AthleticNumbers.macroGrams(value)
    }

    @MainActor
    final class Coordinator: NSObject {
        var onChange: @MainActor (Double) -> Void = { _ in }

        @MainActor
        @objc func changed(_ slider: UISlider) {
            onChange(Double(slider.value))
        }
    }
}
