
struct PrefixedTopLevelConstantConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_private")
    private(set) var onlyPrivateMembers = false
    typealias Parent = PrefixedTopLevelConstantRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $onlyPrivateMembers.key.isEmpty {
            $onlyPrivateMembers.key = "only_private"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$onlyPrivateMembers.key] {
            try onlyPrivateMembers.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
