struct ShorthandArgumentConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "allow_until_line_after_opening_brace")
  private(set) var allowUntilLineAfterOpeningBrace = 4
  @ConfigurationElement(key: "always_disallow_more_than_one")
  private(set) var alwaysDisallowMoreThanOne = false
  @ConfigurationElement(key: "always_disallow_member_access")
  private(set) var alwaysDisallowMemberAccess = false
  typealias Parent = ShorthandArgumentRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowUntilLineAfterOpeningBrace.key] {
      try allowUntilLineAfterOpeningBrace.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysDisallowMoreThanOne.key] {
      try alwaysDisallowMoreThanOne.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysDisallowMemberAccess.key] {
      try alwaysDisallowMemberAccess.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
