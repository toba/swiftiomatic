struct FunctionDefaultParameterAtEndConfiguration: SeverityBasedRuleConfiguration {
    // swiftlint:disable:previous type_name

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_first_isolation_inheritance_parameter")
    private(set) var ignoreFirstIsolationInheritanceParameter = true
    typealias Parent = FunctionDefaultParameterAtEndRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $ignoreFirstIsolationInheritanceParameter.key.isEmpty {
            $ignoreFirstIsolationInheritanceParameter.key = "ignore_first_isolation_inheritance_parameter"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$ignoreFirstIsolationInheritanceParameter.key] {
            try ignoreFirstIsolationInheritanceParameter.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
