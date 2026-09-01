import SwiftUI
import UIKit
import Vision
import VisionKit

/// VisionKit scanner, same contract as the Food apps: QR + EAN, fire as soon as a code is recognised.
@MainActor
struct BarcodeScannerBridge: UIViewControllerRepresentable {
    var isRunning: Bool
    var onPayload: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let symbologies: [VNBarcodeSymbology] = [
            .ean13, .ean8, .upce, .code128, .code39, .qr, .dataMatrix, .pdf417
        ]
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: symbologies)],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        scanner.overlayContainerView.backgroundColor = .clear
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        context.coordinator.onPayload = onPayload
        if isRunning {
            guard !scanner.isScanning, !context.coordinator.didStart else { return }
            context.coordinator.didStart = true
            DispatchQueue.main.async {
                try? scanner.startScanning()
            }
        } else if scanner.isScanning {
            scanner.stopScanning()
            context.coordinator.didStart = false
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
        coordinator.didStart = false
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onPayload: (String) -> Void
        var didStart = false
        private var lastPayload: String?
        private var lastStamp: Date = .distantPast

        init(onPayload: @escaping (String) -> Void) {
            self.onPayload = onPayload
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            emit(item)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                emit(item)
            }
        }

        private func emit(_ item: RecognizedItem) {
            guard case .barcode(let barcode) = item,
                  let payload = barcode.payloadStringValue,
                  payload.isEmpty == false
            else { return }
            let now = Date()
            if payload == lastPayload, now.timeIntervalSince(lastStamp) < 1.8 {
                return
            }
            lastPayload = payload
            lastStamp = now
            let captured = payload
            Task { @MainActor in
                self.onPayload(captured)
            }
        }
    }
}
