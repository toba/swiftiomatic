struct EmptyCountOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.error)
  @OptionElement(key: "only_after_dot")
  private(set) var onlyAfterDot = false
  typealias Parent = EmptyCountRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$onlyAfterDot.key] {
      try onlyAfterDot.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
