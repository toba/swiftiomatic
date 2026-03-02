struct StatementPositionOptions: SeverityBasedRuleOptions {
  enum StatementModeConfiguration: String, AcceptableByOptionElement {
    case `default`
    case uncuddledElse = "uncuddled_else"
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>.warning
  @OptionElement(key: "statement_mode")
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
