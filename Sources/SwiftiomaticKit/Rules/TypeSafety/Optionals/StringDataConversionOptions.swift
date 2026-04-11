struct StringDataConversionOptions: SeverityBasedRuleOptions {
  // sm:disable:previous type_name

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "include_variables")
  private(set) var includeVariables = false
  typealias Parent = StringDataConversionRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$includeVariables.key] {
      try includeVariables.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
