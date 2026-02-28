
struct TestCaseAccessibilityConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allowed_prefixes")
    private(set) var allowedPrefixes: Set<String> = []
    @ConfigurationElement(
        key: "test_parent_classes",
        postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) }
    )
    private(set) var testParentClasses = Set<String>()
    typealias Parent = TestCaseAccessibilityRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $allowedPrefixes.key.isEmpty {
            $allowedPrefixes.key = "allowed_prefixes"
        }
        if $testParentClasses.key.isEmpty {
            $testParentClasses.key = "test_parent_classes"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$allowedPrefixes.key] {
            try allowedPrefixes.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$testParentClasses.key] {
            try testParentClasses.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
