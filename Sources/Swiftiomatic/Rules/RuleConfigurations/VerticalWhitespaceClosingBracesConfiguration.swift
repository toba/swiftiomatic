struct VerticalWhitespaceClosingBracesConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "only_enforce_before_trivial_lines")
  private(set) var onlyEnforceBeforeTrivialLines = false
  typealias Parent = VerticalWhitespaceClosingBracesRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $onlyEnforceBeforeTrivialLines.key.isEmpty {
      $onlyEnforceBeforeTrivialLines.key = "only_enforce_before_trivial_lines"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$onlyEnforceBeforeTrivialLines.key] {
      try onlyEnforceBeforeTrivialLines.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
