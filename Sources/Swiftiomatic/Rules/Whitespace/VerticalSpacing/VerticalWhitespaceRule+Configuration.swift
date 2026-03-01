struct VerticalWhitespaceConfiguration: SeverityBasedRuleOptions {
  static let defaultDescriptionReason = "Limit vertical whitespace to a single empty line"

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "max_empty_lines")
  private(set) var maxEmptyLines = 1

  var configuredDescriptionReason: String {
    guard maxEmptyLines == 1 else {
      return "Limit vertical whitespace to maximum \(maxEmptyLines) empty lines"
    }
    return Self.defaultDescriptionReason
  }

  typealias Parent = VerticalWhitespaceRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$maxEmptyLines.key] {
      try maxEmptyLines.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
