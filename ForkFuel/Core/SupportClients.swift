import AVFoundation
import Foundation
import UIKit
import ComposableArchitecture

struct PreferenceFlagClient: Sendable {
    var ignitionComplete: @Sendable () -> Bool
    var markIgnitionComplete: @Sendable () -> Void
    var consumeDemoSeed: @Sendable () -> Bool
}

enum PreferenceFlagClientKey: DependencyKey {
    static let liveValue = PreferenceFlagClient(
        ignitionComplete: {
            UserDefaults.standard.bool(forKey: PreferenceFlagClient.ignitionKey)
        },
        markIgnitionComplete: {
            UserDefaults.standard.set(true, forKey: PreferenceFlagClient.ignitionKey)
        },
        consumeDemoSeed: {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: PreferenceFlagClient.demoKey) {
                return false
            }
            defaults.set(true, forKey: PreferenceFlagClient.demoKey)
            return true
        }
    )

    static let testValue = PreferenceFlagClient(
        ignitionComplete: { true },
        markIgnitionComplete: { },
        consumeDemoSeed: { false }
    )
}

extension PreferenceFlagClient {
    static let ignitionKey = "ffl.onboarding.v1"
    static let demoKey = "ffl.demo.v1"
}

extension DependencyValues {
    var preferenceFlags: PreferenceFlagClient {
        get { self[PreferenceFlagClientKey.self] }
        set { self[PreferenceFlagClientKey.self] = newValue }
    }
}

struct HapticPulseClient: Sendable {
    var commit: @Sendable () -> Void
}

enum HapticPulseClientKey: DependencyKey {
    static let liveValue = HapticPulseClient {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static let testValue = HapticPulseClient { }
}

extension DependencyValues {
    var hapticPulse: HapticPulseClient {
        get { self[HapticPulseClientKey.self] }
        set { self[HapticPulseClientKey.self] = newValue }
    }
}

struct CalendarClockClient: Sendable {
    var now: @Sendable () -> Date
    var dayKey: @Sendable (Date) -> Date
}

enum CalendarClockClientKey: DependencyKey {
    static let liveValue = CalendarClockClient(
        now: { Date() },
        dayKey: { DayKeyCalendar.key(for: $0) }
    )

    static let testValue = CalendarClockClient(
        now: { Date(timeIntervalSince1970: 1_714_000_000) },
        dayKey: { DayKeyCalendar.key(for: $0) }
    )
}

extension DependencyValues {
    var calendarClock: CalendarClockClient {
        get { self[CalendarClockClientKey.self] }
        set { self[CalendarClockClientKey.self] = newValue }
    }
}

struct SettingsJumpClient: Sendable {
    var open: @Sendable () async -> Void
}

enum SettingsJumpClientKey: DependencyKey {
    static let liveValue = SettingsJumpClient {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        await MainActor.run {
            UIApplication.shared.open(url)
        }
    }

    static let testValue = SettingsJumpClient { }
}

extension DependencyValues {
    var settingsJump: SettingsJumpClient {
        get { self[SettingsJumpClientKey.self] }
        set { self[SettingsJumpClientKey.self] = newValue }
    }
}

enum CaptureAccess: Equatable, Sendable {
    case unknown
    case missingDevice
    case notDetermined
    case denied
    case restricted
    case authorized
}

enum CaptureProbe {
    static func current() -> CaptureAccess {
        if AVCaptureDevice.default(for: .video) == nil {
            return .missingDevice
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }

    static func request() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
