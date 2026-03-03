struct NestingOptions: RuleOptions {
    typealias SeverityLevels = SeverityLevelsConfiguration<Parent>

    @OptionElement(key: "type_level")
    private(set) var typeLevel = SeverityLevels(warning: 1)
    @OptionElement(key: "function_level")
    private(set) var functionLevel = SeverityLevels(warning: 2)
    @OptionElement(key: "check_nesting_in_closures_and_statements")
    private(set) var checkNestingInClosuresAndStatements = true
    @OptionElement(key: "always_allow_one_type_in_functions")
    private(set) var alwaysAllowOneTypeInFunctions = false
    @OptionElement(key: "ignore_typealiases_and_associatedtypes")
    private(set) var ignoreTypealiasesAndAssociatedTypes = false
    @OptionElement(key: "ignore_coding_keys")
    private(set) var ignoreCodingKeys = false

    func severity(with config: SeverityLevels, for level: Int) -> Severity? {
        if let error = config.error, level > error {
            return .error
        }
        if level > config.warning {
            return .warning
        }
        return nil
    }

    func threshold(with config: SeverityLevels, for severity: Severity) -> Int {
        switch severity {
            case .error: return config.error ?? config.warning
            case .warning: return config.warning
        }
    }

    typealias Parent = NestingRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        if let value = configuration[$typeLevel.key] {
            try typeLevel.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$functionLevel.key] {
            try functionLevel.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$checkNestingInClosuresAndStatements.key] {
            try checkNestingInClosuresAndStatements.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$alwaysAllowOneTypeInFunctions.key] {
            try alwaysAllowOneTypeInFunctions.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoreTypealiasesAndAssociatedTypes.key] {
            try ignoreTypealiasesAndAssociatedTypes.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoreCodingKeys.key] {
            try ignoreCodingKeys.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
