struct VerticalWhitespaceClosingBracesConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "only_enforce_before_trivial_lines")
  private(set) var onlyEnforceBeforeTrivialLines = false
  typealias Parent = VerticalWhitespaceClosingBracesRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$onlyEnforceBeforeTrivialLines.key] {
      try onlyEnforceBeforeTrivialLines.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
