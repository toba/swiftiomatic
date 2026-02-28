
struct CyclomaticComplexityConfiguration: RuleConfiguration {
    @ConfigurationElement(inline: true)
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 10, error: 20)
    @ConfigurationElement(key: "ignores_case_statements")
    private(set) var ignoresCaseStatements = false

    var params: [RuleParameter<Int>] {
        length.params
    }

    typealias Parent = CyclomaticComplexityRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $ignoresCaseStatements.key.isEmpty {
            $ignoresCaseStatements.key = "ignores_case_statements"
        }
        do {
            try length.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$ignoresCaseStatements.key] {
            try ignoresCaseStatements.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
