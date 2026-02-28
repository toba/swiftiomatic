struct SwitchCaseAlignmentConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "indented_cases")
  private(set) var indentedCases = false
  @ConfigurationElement(key: "ignore_one_liners")
  private(set) var ignoreOneLiners = false
  typealias Parent = SwitchCaseAlignmentRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $indentedCases.key.isEmpty {
      $indentedCases.key = "indented_cases"
    }
    if $ignoreOneLiners.key.isEmpty {
      $ignoreOneLiners.key = "ignore_one_liners"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$indentedCases.key] {
      try indentedCases.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoreOneLiners.key] {
      try ignoreOneLiners.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
