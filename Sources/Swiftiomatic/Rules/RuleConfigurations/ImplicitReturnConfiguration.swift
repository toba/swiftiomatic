
struct ImplicitReturnConfiguration: SeverityBasedRuleConfiguration {
    enum ReturnKind: String, AcceptableByConfigurationElement, CaseIterable, Comparable {
        case closure
        case function
        case getter
        case `subscript`
        case initializer

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    static let defaultIncludedKinds = Set(ReturnKind.allCases)

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "included")
    private(set) var includedKinds = Self.defaultIncludedKinds

    init(includedKinds: Set<ReturnKind> = Self.defaultIncludedKinds) {
        self.includedKinds = includedKinds
    }

    func isKindIncluded(_ kind: ReturnKind) -> Bool {
        includedKinds.contains(kind)
    }
    typealias Parent = ImplicitReturnRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $includedKinds.key.isEmpty {
            $includedKinds.key = "included"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$includedKinds.key] {
            try includedKinds.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
