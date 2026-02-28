
struct TrailingClosureConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_single_muted_parameter")
    private(set) var onlySingleMutedParameter = false
    typealias Parent = TrailingClosureRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $onlySingleMutedParameter.key.isEmpty {
            $onlySingleMutedParameter.key = "only_single_muted_parameter"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$onlySingleMutedParameter.key] {
            try onlySingleMutedParameter.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
