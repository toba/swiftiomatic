/// Wraps a ``ConfiguredRule`` to provide identity based solely on the rule's identifier
///
/// Two wrappers are equal when their underlying rules share the same identifier,
/// regardless of configuration differences. This enables deduplication in sets and
/// dictionaries keyed by rule identity.
struct RuleIdentityWrapper: Hashable {
    /// The wrapped configured rule
    let configuredRule: ConfiguredRule

    static func == (lhs: Self, rhs: Self) -> Bool {
        // Only use identifier for equality check (not taking config into account)
        type(of: lhs.configuredRule.rule).identifier
            == type(of: rhs.configuredRule.rule).identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type(of: configuredRule.rule).identifier)
    }
}
