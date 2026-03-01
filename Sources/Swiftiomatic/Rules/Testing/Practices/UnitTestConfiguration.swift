typealias BalancedXCTestLifecycleConfiguration = UnitTestConfiguration<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodConfiguration = UnitTestConfiguration<EmptyXCTestMethodRule>
typealias FinalTestCaseConfiguration = UnitTestConfiguration<FinalTestCaseRule>
typealias SingleTestClassConfiguration = UnitTestConfiguration<SingleTestClassRule>
typealias PrivateUnitTestConfiguration = UnitTestConfiguration<PrivateUnitTestRule>

struct UnitTestConfiguration<Parent: Rule>: SeverityBasedRuleOptions {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(
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
