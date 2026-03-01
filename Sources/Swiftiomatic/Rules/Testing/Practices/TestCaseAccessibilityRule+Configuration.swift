struct TestCaseAccessibilityConfiguration: SeverityBasedRuleOptions {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "allowed_prefixes")
  private(set) var allowedPrefixes: Set<String> = []
  @ConfigurationElement(
    key: "test_parent_classes",
    postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) },
  )
  private(set) var testParentClasses = Set<String>()
  typealias Parent = TestCaseAccessibilityRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowedPrefixes.key] {
      try allowedPrefixes.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$testParentClasses.key] {
      try testParentClasses.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
