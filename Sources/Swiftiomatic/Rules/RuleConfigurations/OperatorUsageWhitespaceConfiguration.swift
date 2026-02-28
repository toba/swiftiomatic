struct OperatorUsageWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "lines_look_around")
    private(set) var linesLookAround = 2
    @ConfigurationElement(key: "skip_aligned_constants")
    private(set) var skipAlignedConstants = true
    @ConfigurationElement(key: "allowed_no_space_operators")
    private(set) var allowedNoSpaceOperators = ["...", "..<"]
    typealias Parent = OperatorUsageWhitespaceRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $linesLookAround.key.isEmpty {
            $linesLookAround.key = "lines_look_around"
        }
        if $skipAlignedConstants.key.isEmpty {
            $skipAlignedConstants.key = "skip_aligned_constants"
        }
        if $allowedNoSpaceOperators.key.isEmpty {
            $allowedNoSpaceOperators.key = "allowed_no_space_operators"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$linesLookAround.key] {
            try linesLookAround.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$skipAlignedConstants.key] {
            try skipAlignedConstants.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$allowedNoSpaceOperators.key] {
            try allowedNoSpaceOperators.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
