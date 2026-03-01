/// The magnitude of a `RuleViolation`.
package enum ViolationSeverity: String, AcceptableByConfigurationElement, Comparable, CaseIterable,
    Codable,
    Sendable, InlinableOptionType
{
    /// Non-fatal. Non-fatal severity.
    case warning
    /// Fatal. Fatal severity.
    case error

    // MARK: Comparable

    package static func < (lhs: Self, rhs: Self) -> Bool {
        lhs == .warning && rhs == .error
    }
}
