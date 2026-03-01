struct VerticalWhitespaceBetweenCasesConfiguration: SeverityBasedRuleOptions {
  enum SeparationStyle: String, AcceptableByConfigurationElement {
    case always
    case never
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "separation")
  private(set) var separation: SeparationStyle = .always
  typealias Parent = VerticalWhitespaceBetweenCasesRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$separation.key] {
      try separation.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
