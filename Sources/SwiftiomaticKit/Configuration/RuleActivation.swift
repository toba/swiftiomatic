/// Which rules a configuration turns on, and at what severity, one entry per rule index.
///
/// `Configuration` updates this value on every write to a rule value. A `Context` then reads the
/// sets for each file and does not loop over the rules.
struct RuleActivation: Sendable, Equatable {
    /// The rules whose value is active, which means `rewrite` is on or `lint` is not `.no` .
    private(set) var active = RuleSet()

    /// The rules whose `rewrite` flag is on.
    private(set) var rewrite = RuleSet()

    /// The rules whose `lint` setting is not `.no` .
    private(set) var lint = RuleSet()

    /// The configured `lint` severity of each rule, indexed by rule index.
    private(set) var severities: ContiguousArray<Lint>

    /// The activation of the default value of every rule.
    static let defaults: RuleActivation = {
        var activation = RuleActivation(
            severities: ContiguousArray(repeating: .no, count: ConfigurationRegistry.ruleCount))

        for (index, rule) in ConfigurationRegistry.allRuleTypes.enumerated() {
            activation.update(ruleAt: index, with: rule.defaultRuleValue)
        }
        return activation
    }()

    private init(severities: ContiguousArray<Lint>) { self.severities = severities }

    /// Records `value` as the value of the rule at `index` .
    mutating func update(ruleAt index: Int, with value: some SyntaxRuleValue) {
        active[index] = value.isActive
        rewrite[index] = value.isRewriteActive
        lint[index] = value.lint.isActive
        severities[index] = value.lint
    }
}

extension SyntaxRule {
    /// The default value, erased so a caller that holds `any SyntaxRule.Type` can read it.
    static var defaultRuleValue: any SyntaxRuleValue { defaultValue }
}
