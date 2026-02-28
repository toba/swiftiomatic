struct VerticalWhitespaceConfiguration: SeverityBasedRuleConfiguration {
  static let defaultDescriptionReason = "Limit vertical whitespace to a single empty line"

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "max_empty_lines")
  private(set) var maxEmptyLines = 1

  var configuredDescriptionReason: String {
    guard maxEmptyLines == 1 else {
      return "Limit vertical whitespace to maximum \(maxEmptyLines) empty lines"
    }
    return Self.defaultDescriptionReason
  }

  typealias Parent = VerticalWhitespaceRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $maxEmptyLines.key.isEmpty {
      $maxEmptyLines.key = "max_empty_lines"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$maxEmptyLines.key] {
      try maxEmptyLines.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
