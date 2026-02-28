
struct ColonConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "flexible_right_spacing")
    private(set) var flexibleRightSpacing = false
    @ConfigurationElement(key: "apply_to_dictionaries")
    private(set) var applyToDictionaries = true
    typealias Parent = ColonRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $flexibleRightSpacing.key.isEmpty {
            $flexibleRightSpacing.key = "flexible_right_spacing"
        }
        if $applyToDictionaries.key.isEmpty {
            $applyToDictionaries.key = "apply_to_dictionaries"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$flexibleRightSpacing.key] {
            try flexibleRightSpacing.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$applyToDictionaries.key] {
            try applyToDictionaries.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
