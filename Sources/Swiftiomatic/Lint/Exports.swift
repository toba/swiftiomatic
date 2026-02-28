private let _registerAllRulesOnceImpl: Void = {
    RuleRegistry.shared.register(rules: builtInRules + coreRules + extraRules())
}()

extension RuleRegistry {
    /// Register all rules. Should only be called once before any linting code is executed.
    static func registerAllRulesOnce() {
        _ = _registerAllRulesOnceImpl
    }
}
