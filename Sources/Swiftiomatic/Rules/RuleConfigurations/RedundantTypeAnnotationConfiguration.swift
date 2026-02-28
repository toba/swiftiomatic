
struct RedundantTypeAnnotationConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_attributes")
    var ignoreAttributes = Set<String>(["IBInspectable"])
    @ConfigurationElement(key: "ignore_properties")
    private(set) var ignoreProperties = false
    @ConfigurationElement(key: "consider_default_literal_types_redundant")
    private(set) var considerDefaultLiteralTypesRedundant = false
    typealias Parent = RedundantTypeAnnotationRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $ignoreAttributes.key.isEmpty {
            $ignoreAttributes.key = "ignore_attributes"
        }
        if $ignoreProperties.key.isEmpty {
            $ignoreProperties.key = "ignore_properties"
        }
        if $considerDefaultLiteralTypesRedundant.key.isEmpty {
            $considerDefaultLiteralTypesRedundant.key = "consider_default_literal_types_redundant"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$ignoreAttributes.key] {
            try ignoreAttributes.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoreProperties.key] {
            try ignoreProperties.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$considerDefaultLiteralTypesRedundant.key] {
            try considerDefaultLiteralTypesRedundant.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
