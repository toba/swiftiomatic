struct TrailingWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignores_empty_lines")
    private(set) var ignoresEmptyLines = false
    @ConfigurationElement(key: "ignores_comments")
    private(set) var ignoresComments = true
    @ConfigurationElement(key: "ignores_literals")
    private(set) var ignoresLiterals = false
    typealias Parent = TrailingWhitespaceRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $ignoresEmptyLines.key.isEmpty {
            $ignoresEmptyLines.key = "ignores_empty_lines"
        }
        if $ignoresComments.key.isEmpty {
            $ignoresComments.key = "ignores_comments"
        }
        if $ignoresLiterals.key.isEmpty {
            $ignoresLiterals.key = "ignores_literals"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$ignoresEmptyLines.key] {
            try ignoresEmptyLines.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoresComments.key] {
            try ignoresComments.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$ignoresLiterals.key] {
            try ignoresLiterals.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
