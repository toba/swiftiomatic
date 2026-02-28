
struct BlanketDisableCommandConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allowed_rules")
    private(set) var allowedRuleIdentifiers: Set<String> = [
        "file_header",
        "file_length",
        "file_name",
        "file_name_no_space",
        "single_test_class",
    ]
    @ConfigurationElement(key: "always_blanket_disable")
    private(set) var alwaysBlanketDisableRuleIdentifiers: Set<String> = []
    typealias Parent = BlanketDisableCommandRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $allowedRuleIdentifiers.key.isEmpty {
            $allowedRuleIdentifiers.key = "allowed_rules"
        }
        if $alwaysBlanketDisableRuleIdentifiers.key.isEmpty {
            $alwaysBlanketDisableRuleIdentifiers.key = "always_blanket_disable"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$allowedRuleIdentifiers.key] {
            try allowedRuleIdentifiers.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$alwaysBlanketDisableRuleIdentifiers.key] {
            try alwaysBlanketDisableRuleIdentifiers.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
