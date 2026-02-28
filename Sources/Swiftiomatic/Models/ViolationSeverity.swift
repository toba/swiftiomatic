/// The magnitude of a `RuleViolation`.
enum ViolationSeverity: String, AcceptableByConfigurationElement, Comparable, CaseIterable, Codable,
    Sendable, InlinableOptionType
{
    /// Non-fatal. Non-fatal severity.
    case warning
    /// Fatal. Fatal severity.
    case error

    // MARK: Comparable

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs == .warning && rhs == .error
    }
}
