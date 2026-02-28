struct TrailingCommaConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "mandatory_comma")
  private(set) var mandatoryComma = false
  typealias Parent = TrailingCommaRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $mandatoryComma.key.isEmpty {
      $mandatoryComma.key = "mandatory_comma"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$mandatoryComma.key] {
      try mandatoryComma.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
