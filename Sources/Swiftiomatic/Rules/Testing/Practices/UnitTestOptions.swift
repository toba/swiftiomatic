typealias BalancedXCTestLifecycleOptions = UnitTestOptions<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodOptions = UnitTestOptions<EmptyXCTestMethodRule>
typealias FinalTestCaseOptions = UnitTestOptions<FinalTestCaseRule>
typealias SingleTestClassOptions = UnitTestOptions<SingleTestClassRule>
typealias PrivateUnitTestOptions = UnitTestOptions<PrivateUnitTestRule>

struct UnitTestOptions<Parent: Rule>: SeverityBasedRuleOptions {
    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>(.warning)
    @OptionElement(
        key: "test_parent_classes",
        postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) },
    )
    private(set) var testParentClasses = Set<String>()
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$testParentClasses.key] {
            try testParentClasses.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
