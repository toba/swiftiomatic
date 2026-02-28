struct UnneededOverrideConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "affect_initializers")
    private(set) var affectInits = false
    @ConfigurationElement(key: "excluded_methods")
    private(set) var excludedMethods = Set<String>()
    typealias Parent = UnneededOverrideRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $affectInits.key.isEmpty {
            $affectInits.key = "affect_initializers"
        }
        if $excludedMethods.key.isEmpty {
            $excludedMethods.key = "excluded_methods"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$affectInits.key] {
            try affectInits.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$excludedMethods.key] {
            try excludedMethods.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
