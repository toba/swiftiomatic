struct RedundantOverrideOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "affect_initializers")
  private(set) var affectInits = false
  @OptionElement(key: "excluded_methods")
  private(set) var excludedMethods = Set<String>()
  typealias Parent = RedundantOverrideRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$affectInits.key] {
      try affectInits.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$excludedMethods.key] {
      try excludedMethods.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
