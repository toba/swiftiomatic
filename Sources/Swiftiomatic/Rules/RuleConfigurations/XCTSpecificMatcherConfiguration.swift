
struct XCTSpecificMatcherConfiguration: SeverityBasedRuleConfiguration {
    enum Matcher: String, AcceptableByConfigurationElement, CaseIterable {
        case oneArgumentAsserts = "one-argument-asserts"
        case twoArgumentAsserts = "two-argument-asserts"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "matchers")
    private(set) var matchers = Matcher.allCases
    typealias Parent = XCTSpecificMatcherRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $matchers.key.isEmpty {
            $matchers.key = "matchers"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$matchers.key] {
            try matchers.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
