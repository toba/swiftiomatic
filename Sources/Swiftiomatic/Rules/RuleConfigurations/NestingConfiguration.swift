
struct NestingConfiguration: RuleConfiguration {
    typealias Severity = SeverityLevelsConfiguration<Parent>

    @ConfigurationElement(key: "type_level")
    private(set) var typeLevel = Severity(warning: 1)
    @ConfigurationElement(key: "function_level")
    private(set) var functionLevel = Severity(warning: 2)
    @ConfigurationElement(key: "check_nesting_in_closures_and_statements")
    private(set) var checkNestingInClosuresAndStatements = true
    @ConfigurationElement(key: "always_allow_one_type_in_functions")
    private(set) var alwaysAllowOneTypeInFunctions = false
    @ConfigurationElement(key: "ignore_typealiases_and_associatedtypes")
    private(set) var ignoreTypealiasesAndAssociatedtypes = false
    @ConfigurationElement(key: "ignore_coding_keys")
    private(set) var ignoreCodingKeys = false

    func severity(with config: Severity, for level: Int) -> ViolationSeverity? {
        if let error = config.error, level > error {
            return .error
        }
        if level > config.warning {
            return .warning
        }
        return nil
    }

    func threshold(with config: Severity, for severity: ViolationSeverity) -> Int {
        switch severity {
        case .error: return config.error ?? config.warning
        case .warning: return config.warning
        }
    }
    typealias Parent = NestingRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $typeLevel.key.isEmpty {
            $typeLevel.key = "type_level"
        }
        if $functionLevel.key.isEmpty {
            $functionLevel.key = "function_level"
        }
        if $checkNestingInClosuresAndStatements.key.isEmpty {
            $checkNestingInClosuresAndStatements.key = "check_nesting_in_closures_and_statements"
        }
        if $alwaysAllowOneTypeInFunctions.key.isEmpty {
            $alwaysAllowOneTypeInFunctions.key = "always_allow_one_type_in_functions"
        }
        if $ignoreTypealiasesAndAssociatedtypes.key.isEmpty {
            $ignoreTypealiasesAndAssociatedtypes.key = "ignore_typealiases_and_associatedtypes"
        }
        if $ignoreCodingKeys.key.isEmpty {
            $ignoreCodingKeys.key = "ignore_coding_keys"
        }
        guard let configuration = configuration as? [String: Any] else {
            throw .invalidConfiguration(ruleID: Parent.identifier)
        }
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
        if let value = configuration[$ignoreTypealiasesAndAssociatedtypes.key] {
            try ignoreTypealiasesAndAssociatedtypes.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoreCodingKeys.key] {
            try ignoreCodingKeys.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
