struct ImplicitlyUnwrappedOptionalConfiguration: SeverityBasedRuleConfiguration {
    enum ImplicitlyUnwrappedOptionalModeConfiguration: String,
        AcceptableByConfigurationElement
    { // sm:disable:this type_name
        case all
        case allExceptIBOutlets = "all_except_iboutlets"
        case weakExceptIBOutlets = "weak_except_iboutlets"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "mode")
    private(set) var mode = ImplicitlyUnwrappedOptionalModeConfiguration.allExceptIBOutlets
    typealias Parent = ImplicitlyUnwrappedOptionalRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $mode.key.isEmpty {
            $mode.key = "mode"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$mode.key] {
            try mode.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
