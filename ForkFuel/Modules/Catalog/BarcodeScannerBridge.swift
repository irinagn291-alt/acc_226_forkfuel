import SwiftUI
import UIKit
import VisionKit

/// VisionKit barcode scanner. Tap a recognised code. Coordinator round-trips the payload.
@MainActor
struct BarcodeScannerBridge: UIViewControllerRepresentable {
    var isRunning: Bool
    var onPayload: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean8, .ean13, .upce, .qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        scanner.overlayContainerView.backgroundColor = .clear
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        context.coordinator.onPayload = onPayload
        if isRunning {
            if !scanner.isScanning {
                try? scanner.startScanning()
            }
        } else if scanner.isScanning {
            scanner.stopScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        if scanner.isScanning {
            scanner.stopScanning()
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onPayload: (String) -> Void
        private var lastPayload: String?
        private var lastStamp: Date = .distantPast

        init(onPayload: @escaping (String) -> Void) {
            self.onPayload = onPayload
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            guard case .barcode(let barcode) = item else { return }
            guard let payload = barcode.payloadStringValue, !payload.isEmpty else { return }
            let now = Date()
            if payload == lastPayload, now.timeIntervalSince(lastStamp) < 1.8 {
                return
            }
            lastPayload = payload
            lastStamp = now
            onPayload(payload)
        }
    }
}
