struct RuleIdentityWrapper: Hashable {
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
