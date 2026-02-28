struct EmptyCountConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.error)
    @ConfigurationElement(key: "only_after_dot")
    private(set) var onlyAfterDot = false
    typealias Parent = EmptyCountRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $onlyAfterDot.key.isEmpty {
            $onlyAfterDot.key = "only_after_dot"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$onlyAfterDot.key] {
            try onlyAfterDot.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
