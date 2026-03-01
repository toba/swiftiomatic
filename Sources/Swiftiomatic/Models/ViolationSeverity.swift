/// The magnitude of a `RuleViolation`.
package enum ViolationSeverity: String, AcceptableByConfigurationElement, Comparable, CaseIterable,
    Codable,
    Sendable, InlinableOption
{
    /// Non-fatal severity. Issues are reported but do not cause a non-zero exit code.
    case warning
    /// Fatal severity. Issues cause a non-zero exit code and block CI.
    case error

    // MARK: Comparable

    package static func < (lhs: Self, rhs: Self) -> Bool {
        lhs == .warning && rhs == .error
    }
}
