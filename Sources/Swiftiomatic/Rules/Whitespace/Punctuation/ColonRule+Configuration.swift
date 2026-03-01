struct ColonConfiguration: SeverityBasedRuleOptions {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "flexible_right_spacing")
  private(set) var flexibleRightSpacing = false
  @ConfigurationElement(key: "apply_to_dictionaries")
  private(set) var applyToDictionaries = true
  typealias Parent = ColonRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$flexibleRightSpacing.key] {
      try flexibleRightSpacing.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$applyToDictionaries.key] {
      try applyToDictionaries.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
