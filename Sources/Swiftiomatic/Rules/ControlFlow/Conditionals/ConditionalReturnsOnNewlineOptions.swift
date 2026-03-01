struct ConditionalReturnsOnNewlineOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "if_only")
  private(set) var ifOnly = false
  typealias Parent = ConditionalReturnsOnNewlineRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$ifOnly.key] {
      try ifOnly.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
