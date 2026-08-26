import SwiftUI
import UIKit

/// UIPickerView gram wheel. Coordinator writes the selected gram count back into SwiftUI.
@MainActor
struct GramWheelBridge: UIViewRepresentable {
    @Binding var grams: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(grams: $grams)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.backgroundColor = UIColor(named: "ffl_surface")
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.grams = $grams
        let row = context.coordinator.row(for: grams)
        if picker.selectedRow(inComponent: 0) != row {
            picker.selectRow(row, inComponent: 0, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var grams: Binding<Int>
        let values = Array(1...500)

        init(grams: Binding<Int>) {
            self.grams = grams
        }

        func row(for value: Int) -> Int {
            min(max(value, 1), 500) - 1
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            values.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            AthleticSpace.tap
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.textAlignment = .center
            label.textColor = UIColor(named: "ffl_ink")
            label.font = AthleticTypeScale.uiTitle()
            label.text = "\(values[row]) g"
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            grams.wrappedValue = values[row]
        }
    }
}
