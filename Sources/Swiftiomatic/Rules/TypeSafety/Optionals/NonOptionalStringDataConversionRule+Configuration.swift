struct NonOptionalStringDataConversionConfiguration: SeverityBasedRuleConfiguration {
  // sm:disable:previous type_name

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "include_variables")
  private(set) var includeVariables = false
  typealias Parent = NonOptionalStringDataConversionRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$includeVariables.key] {
      try includeVariables.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
