
struct ExplicitTypeInterfaceConfiguration: SeverityBasedRuleConfiguration {
    enum VariableKind: String, AcceptableByConfigurationElement, CaseIterable {
        case instance
        case local
        case `static`
        case `class`

        static let all = Set(allCases)
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = [VariableKind]()
    @ConfigurationElement(key: "allow_redundancy")
    private(set) var allowRedundancy = false

    var allowedKinds: Set<VariableKind> {
        VariableKind.all.subtracting(excluded)
    }
    typealias Parent = ExplicitTypeInterfaceRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $excluded.key.isEmpty {
            $excluded.key = "excluded"
        }
        if $allowRedundancy.key.isEmpty {
            $allowRedundancy.key = "allow_redundancy"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$excluded.key] {
            try excluded.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$allowRedundancy.key] {
            try allowRedundancy.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
