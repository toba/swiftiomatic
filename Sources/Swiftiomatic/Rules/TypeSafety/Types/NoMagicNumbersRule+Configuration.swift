struct NoMagicNumbersConfiguration: SeverityBasedRuleOptions {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(
    key: "test_parent_classes",
    postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) },
  )
  private(set) var testParentClasses = Set<String>()
  @ConfigurationElement(
    key: "allowed_numbers",
    postprocessor: { $0.formUnion([0, 1, 100]) },
  )
  private(set) var allowedNumbers = Set<Double>()
  typealias Parent = NoMagicNumbersRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$testParentClasses.key] {
      try testParentClasses.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$allowedNumbers.key] {
      try allowedNumbers.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
