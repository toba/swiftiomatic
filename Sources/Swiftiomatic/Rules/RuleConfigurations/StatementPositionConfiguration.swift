
struct StatementPositionConfiguration: SeverityBasedRuleConfiguration {
    enum StatementModeConfiguration: String, AcceptableByConfigurationElement {
        case `default` = "default"
        case uncuddledElse = "uncuddled_else"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "statement_mode")
    private(set) var statementMode = StatementModeConfiguration.default
    typealias Parent = StatementPositionRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $statementMode.key.isEmpty {
            $statementMode.key = "statement_mode"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$statementMode.key] {
            try statementMode.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
