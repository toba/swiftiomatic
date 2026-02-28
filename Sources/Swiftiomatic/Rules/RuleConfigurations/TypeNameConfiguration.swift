struct TypeNameConfiguration: RuleConfiguration {
    @ConfigurationElement(inline: true)
    private(set) var nameConfiguration = NameConfiguration<Parent>(
        minLengthWarning: 3,
        minLengthError: 0,
        maxLengthWarning: 40,
        maxLengthError: 1000,
    )
    @ConfigurationElement(key: "validate_protocols")
    private(set) var validateProtocols = true
    typealias Parent = TypeNameRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $validateProtocols.key.isEmpty {
            $validateProtocols.key = "validate_protocols"
        }
        do {
            try nameConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$validateProtocols.key] {
            try validateProtocols.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
