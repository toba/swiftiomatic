
struct NonOptionalStringDataConversionConfiguration: SeverityBasedRuleConfiguration {
    // swiftlint:disable:previous type_name

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_variables")
    private(set) var includeVariables = false
    typealias Parent = NonOptionalStringDataConversionRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $includeVariables.key.isEmpty {
            $includeVariables.key = "include_variables"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$includeVariables.key] {
            try includeVariables.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
