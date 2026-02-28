struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "ignore_optional_try")
  private(set) var ignoreOptionalTry = false
  typealias Parent = UnusedOptionalBindingRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $ignoreOptionalTry.key.isEmpty {
      $ignoreOptionalTry.key = "ignore_optional_try"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$ignoreOptionalTry.key] {
      try ignoreOptionalTry.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
