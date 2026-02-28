struct RedundantSelfConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "keep_in_initializers")
    private(set) var keepInInitializers = false
    @ConfigurationElement(key: "only_in_closures")
    private(set) var onlyInClosures = true
    typealias Parent = RedundantSelfRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $keepInInitializers.key.isEmpty {
            $keepInInitializers.key = "keep_in_initializers"
        }
        if $onlyInClosures.key.isEmpty {
            $onlyInClosures.key = "only_in_closures"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$keepInInitializers.key] {
            try keepInInitializers.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$onlyInClosures.key] {
            try onlyInClosures.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
