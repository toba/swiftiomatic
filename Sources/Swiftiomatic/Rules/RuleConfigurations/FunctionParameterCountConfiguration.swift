struct FunctionParameterCountConfiguration: RuleConfiguration {
    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 5, error: 8)
    @ConfigurationElement(key: "ignores_default_parameters")
    private(set) var ignoresDefaultParameters = true
    typealias Parent = FunctionParameterCountRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $ignoresDefaultParameters.key.isEmpty {
            $ignoresDefaultParameters.key = "ignores_default_parameters"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$ignoresDefaultParameters.key] {
            try ignoresDefaultParameters.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
