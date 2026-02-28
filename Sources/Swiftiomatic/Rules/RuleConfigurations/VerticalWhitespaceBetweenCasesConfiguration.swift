
struct VerticalWhitespaceBetweenCasesConfiguration: SeverityBasedRuleConfiguration {
    enum SeparationStyle: String, AcceptableByConfigurationElement {
        case always
        case never
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "separation")
    private(set) var separation: SeparationStyle = .always
    typealias Parent = VerticalWhitespaceBetweenCasesRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $separation.key.isEmpty {
            $separation.key = "separation"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$separation.key] {
            try separation.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
