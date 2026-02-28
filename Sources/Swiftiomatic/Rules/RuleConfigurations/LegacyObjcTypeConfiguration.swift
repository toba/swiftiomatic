
struct LegacyObjcTypeConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "allowed_types")
    private(set) var allowedTypes: Set<String> = []
    typealias Parent = LegacyObjcTypeRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $allowedTypes.key.isEmpty {
            $allowedTypes.key = "allowed_types"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$allowedTypes.key] {
            try allowedTypes.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
