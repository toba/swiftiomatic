struct TrailingWhitespaceOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "ignores_empty_lines")
  private(set) var ignoresEmptyLines = false
  @OptionElement(key: "ignores_comments")
  private(set) var ignoresComments = true
  @OptionElement(key: "ignores_literals")
  private(set) var ignoresLiterals = false
  typealias Parent = TrailingWhitespaceRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$ignoresEmptyLines.key] {
      try ignoresEmptyLines.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoresComments.key] {
      try ignoresComments.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoresLiterals.key] {
      try ignoresLiterals.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
