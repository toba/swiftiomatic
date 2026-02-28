struct LargeTupleConfiguration: RuleConfiguration {
  @ConfigurationElement(inline: true)
  private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 2,
    error: 3,
  )
  @ConfigurationElement(key: "ignore_regex")
  private(set) var ignoreRegex = false
  typealias Parent = LargeTupleRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $ignoreRegex.key.isEmpty {
      $ignoreRegex.key = "ignore_regex"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$ignoreRegex.key] {
      try ignoreRegex.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
