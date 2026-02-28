
struct PrivateOverFilePrivateConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "validate_extensions")
    var validateExtensions = false
    typealias Parent = PrivateOverFilePrivateRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $validateExtensions.key.isEmpty {
            $validateExtensions.key = "validate_extensions"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$validateExtensions.key] {
            try validateExtensions.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
