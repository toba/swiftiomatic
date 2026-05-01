/// Finding severity for syntax rules.
package enum Lint: String, Hashable, Sendable, Codable {
    /// No findings emitted. A rewrite rule with `.no` fixes silently.
    case no
    /// Findings are reported as warnings.
    case warn
    /// Findings are reported as errors.
    case error

    /// Whether findings should be emitted.
    package var isActive: Bool { self != .no }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        switch raw {
            case "warn": self = .warn
            case "error": self = .error
            case "no", "none": self = .no  // accept legacy "none"
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription:
                        "Invalid lint value '\(raw)'. Expected 'warn', 'error', or 'no'."
                )
        }
    }
}
