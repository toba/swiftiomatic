struct StatementPositionConfiguration: SeverityBasedRuleConfiguration {
  enum StatementModeConfiguration: String, AcceptableByConfigurationElement {
    case `default`
    case uncuddledElse = "uncuddled_else"
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>.warning
  @ConfigurationElement(key: "statement_mode")
  private(set) var statementMode = StatementModeConfiguration.default
  typealias Parent = StatementPositionRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$statementMode.key] {
      try statementMode.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
