enum TypeBodyLengthCheckType: String, AcceptableByConfigurationElement, CaseIterable, Comparable {
    case `actor`
    case `class`
    case `enum`
    case `extension`
    case `protocol`
    case `struct`

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct TypeBodyLengthConfiguration: SeverityLevelsBasedRuleConfiguration {
    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(
        warning: 250, error: 350,
    )
    @ConfigurationElement(key: "excluded_types")
    private(set) var excludedTypes = Set<TypeBodyLengthCheckType>([.extension, .protocol])
    typealias Parent = TypeBodyLengthRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $excludedTypes.key.isEmpty {
            $excludedTypes.key = "excluded_types"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$excludedTypes.key] {
            try excludedTypes.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
