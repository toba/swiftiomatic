struct UnusedOptionalBindingOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "ignore_optional_try")
  private(set) var ignoreOptionalTry = false
  typealias Parent = UnusedOptionalBindingRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$ignoreOptionalTry.key] {
      try ignoreOptionalTry.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
