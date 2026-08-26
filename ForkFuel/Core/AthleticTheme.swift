import SwiftUI
import UIKit

/// Typed colour accessor. Named colours live in the asset catalog; hex never appears outside those sets.
enum AthleticPalette {
    static var background: Color { Color("ffl_background") }
    static var surface: Color { Color("ffl_surface") }
    static var ink: Color { Color("ffl_ink") }
    static var accent: Color { Color("ffl_accent") }
    static var muted: Color { Color("ffl_muted") }
}

/// Avenir Next type scale. Font names are declared only here. Six steps maximum.
enum AthleticTypeScale {
    static func energyDisplay() -> Font {
        .custom(heavyName, size: 44, relativeTo: .largeTitle)
    }

    static func heading() -> Font {
        .custom(demiName, size: 28, relativeTo: .title)
    }

    static func title() -> Font {
        .custom(demiName, size: 20, relativeTo: .headline)
    }

    static func body() -> Font {
        .custom(regularName, size: 17, relativeTo: .body)
    }

    static func caption() -> Font {
        .custom(regularName, size: 14, relativeTo: .footnote)
    }

    static func micro() -> Font {
        .custom(regularName, size: 12, relativeTo: .caption2)
    }

    static func uiTitle() -> UIFont {
        UIFont(name: demiName, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold)
    }

    static func uiBody() -> UIFont {
        UIFont(name: regularName, size: 17) ?? UIFont.systemFont(ofSize: 17)
    }

    private static let heavyName = "AvenirNext-Heavy"
    private static let demiName = "AvenirNext-DemiBold"
    private static let regularName = "AvenirNext-Regular"
}

/// Single spacing grid: 8 pt and its multiples.
enum AthleticSpace {
    static let unit: CGFloat = 8

    static func x(_ steps: CGFloat) -> CGFloat {
        unit * steps
    }

    static let corner: CGFloat = 8
    static let tap: CGFloat = 44
}

/// Shared motion. One easing curve, 0.28 s. Reduce Motion swaps to a short fade.
enum AthleticMotion {
    static let duration: Double = 0.28

    static var curve: Animation {
        .easeInOut(duration: duration)
    }

    static func allowed(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.16) : curve
    }
}

/// Locale-aware number formatting. Round only at display. Formatters are created per call so this stays nonisolated.
enum AthleticNumbers {
    static func energyKcal(_ value: Double) -> String {
        makeFormatter(fraction: 0).string(from: NSNumber(value: value.rounded())) ?? "—"
    }

    static func energyKcal(_ value: Double?) -> String {
        guard let value else { return "—" }
        return energyKcal(value)
    }

    static func macroGrams(_ value: Double?) -> String {
        guard let value else { return "—" }
        return makeFormatter(fraction: 1).string(from: NSNumber(value: value)) ?? "—"
    }

    static func grams(_ value: Double) -> String {
        makeFormatter(fraction: 1).string(from: NSNumber(value: value)) ?? "—"
    }

    static func parseDecimal(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return formatter.number(from: trimmed)?.doubleValue
    }

    private static func makeFormatter(fraction: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fraction
        formatter.minimumFractionDigits = 0
        return formatter
    }
}
