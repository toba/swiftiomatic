struct XCTSpecificMatcherConfiguration: SeverityBasedRuleConfiguration {
  enum Matcher: String, AcceptableByConfigurationElement, CaseIterable {
    case oneArgumentAsserts = "one-argument-asserts"
    case twoArgumentAsserts = "two-argument-asserts"
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "matchers")
  private(set) var matchers = Matcher.allCases
  typealias Parent = XCTSpecificMatcherRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$matchers.key] {
      try matchers.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
