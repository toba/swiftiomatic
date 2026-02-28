
struct IdentifierNameConfiguration: RuleConfiguration {
    private static let defaultOperators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", ".", "%", "<", ">", "&"]

    @ConfigurationElement(inline: true)
    private(set) var nameConfiguration = NameConfiguration<Parent>(minLengthWarning: 3,
                                                                   minLengthError: 2,
                                                                   maxLengthWarning: 40,
                                                                   maxLengthError: 60,
                                                                   excluded: ["id"])

    @ConfigurationElement(key: "additional_operators", postprocessor: { $0.formUnion(Self.defaultOperators) })
    private(set) var additionalOperators = Set<String>()
    typealias Parent = IdentifierNameRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $additionalOperators.key.isEmpty {
            $additionalOperators.key = "additional_operators"
        }
        do {
            try nameConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$additionalOperators.key] {
            try additionalOperators.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
