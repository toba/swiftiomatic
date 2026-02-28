
struct MultilineCallArgumentsConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allows_single_line")
    private(set) var allowsSingleLine = true
    @ConfigurationElement(key: "max_number_of_single_line_parameters")
    private(set) var maxNumberOfSingleLineParameters: Int?

    func validate() throws(Issue) {
        guard let maxNumberOfSingleLineParameters else {
            return
        }
        guard maxNumberOfSingleLineParameters >= 1 else {
            throw Issue.inconsistentConfiguration(
                ruleID: Parent.identifier,
                message: "Option '\($maxNumberOfSingleLineParameters.key)' should be >= 1."
            )
        }

        if maxNumberOfSingleLineParameters > 1, !allowsSingleLine {
            throw Issue.inconsistentConfiguration(
                ruleID: Parent.identifier,
                message: """
                         Option '\($maxNumberOfSingleLineParameters.key)' has no effect when \
                         '\($allowsSingleLine.key)' is false.
                         """
            )
        }
    }
    typealias Parent = MultilineCallArgumentsRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $allowsSingleLine.key.isEmpty {
            $allowsSingleLine.key = "allows_single_line"
        }
        if $maxNumberOfSingleLineParameters.key.isEmpty {
            $maxNumberOfSingleLineParameters.key = "max_number_of_single_line_parameters"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$allowsSingleLine.key] {
            try allowsSingleLine.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$maxNumberOfSingleLineParameters.key] {
            try maxNumberOfSingleLineParameters.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
