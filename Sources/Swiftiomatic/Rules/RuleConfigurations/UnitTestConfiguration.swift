typealias BalancedXCTestLifecycleConfiguration = UnitTestConfiguration<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodConfiguration = UnitTestConfiguration<EmptyXCTestMethodRule>
typealias FinalTestCaseConfiguration = UnitTestConfiguration<FinalTestCaseRule>
typealias SingleTestClassConfiguration = UnitTestConfiguration<SingleTestClassRule>
typealias PrivateUnitTestConfiguration = UnitTestConfiguration<PrivateUnitTestRule>

struct UnitTestConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(
        key: "test_parent_classes",
        postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) },
    )
    private(set) var testParentClasses = Set<String>()
    mutating func apply(configuration: Any) throws(Issue) {
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
