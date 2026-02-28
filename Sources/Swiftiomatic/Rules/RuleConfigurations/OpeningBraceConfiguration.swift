struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_multiline_type_headers")
    private(set) var ignoreMultilineTypeHeaders = false
    @ConfigurationElement(key: "ignore_multiline_statement_conditions")
    private(set) var ignoreMultilineStatementConditions = false
    @ConfigurationElement(key: "ignore_multiline_function_signatures")
    private(set) var ignoreMultilineFunctionSignatures = false
    // TODO: [08/23/2026] Remove deprecation warning after ~2 years.
    @ConfigurationElement(
        key: "allow_multiline_func",
        deprecationNotice: .suggestAlternative(
            ruleID: Parent.identifier, name: "ignore_multiline_function_signatures",
        ),
    )
    private(set) var allowMultilineFunc = false

    var shouldIgnoreMultilineFunctionSignatures: Bool {
        ignoreMultilineFunctionSignatures || allowMultilineFunc
    }

    typealias Parent = OpeningBraceRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $ignoreMultilineTypeHeaders.key.isEmpty {
            $ignoreMultilineTypeHeaders.key = "ignore_multiline_type_headers"
        }
        if $ignoreMultilineStatementConditions.key.isEmpty {
            $ignoreMultilineStatementConditions.key = "ignore_multiline_statement_conditions"
        }
        if $ignoreMultilineFunctionSignatures.key.isEmpty {
            $ignoreMultilineFunctionSignatures.key = "ignore_multiline_function_signatures"
        }
        if $allowMultilineFunc.key.isEmpty {
            $allowMultilineFunc.key = "allow_multiline_func"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$ignoreMultilineTypeHeaders.key] {
            try ignoreMultilineTypeHeaders.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoreMultilineStatementConditions.key] {
            try ignoreMultilineStatementConditions.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoreMultilineFunctionSignatures.key] {
            try ignoreMultilineFunctionSignatures.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$allowMultilineFunc.key] {
            try allowMultilineFunc.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
