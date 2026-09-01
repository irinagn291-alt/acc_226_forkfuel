import Foundation

/// Extracts and normalises barcode payloads from camera, typed text, or pasted URLs.
enum BarcodeNormaliser {
    static func digitRuns(in raw: String) -> [String] {
        var runs: [String] = []
        var current = ""
        for character in raw where character.isASCII {
            if character.isNumber {
                current.append(character)
            } else if !current.isEmpty {
                runs.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            runs.append(current)
        }
        return runs
    }

    static func normalise(_ run: String) -> String? {
        guard (8...14).contains(run.count) else { return nil }
        if run.count == 12 {
            return "0" + run
        }
        return run
    }

    /// Every plausible candidate, tried in order before reporting a miss.
    static func candidates(from raw: String) -> [String] {
        var ordered: [String] = []
        var seen = Set<String>()
        func append(_ value: String) {
            guard seen.insert(value).inserted else { return }
            ordered.append(value)
        }
        for run in digitRuns(in: raw) {
            guard let normalised = normalise(run) else { continue }
            append(normalised)
            if run.count == 12 {
                append(run)
            }
            if normalised.hasPrefix("0"), normalised.count == 14 {
                append(String(normalised.dropFirst()))
            }
            if normalised.hasPrefix("0"), normalised.count == 13 {
                let trimmed = String(normalised.dropFirst())
                if trimmed.count == 12 {
                    append(trimmed)
                }
            }
        }
        return ordered
    }

    static func firstValid(from raw: String) -> String? {
        candidates(from: raw).first
    }
}
