/// The magnitude of a rule violation — warning or error.
public enum Severity: String, Comparable, CaseIterable, Codable, Sendable {
    /// Non-fatal severity. Issues are reported but do not cause a non-zero exit code.
    case warning
    /// Fatal severity. Issues cause a non-zero exit code and block CI.
    case error

    // MARK: Comparable

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs == .warning && rhs == .error
    }
}

// MARK: - Configuration Conformances

extension Severity: AcceptableByConfigurationElement, InlinableOption {}
