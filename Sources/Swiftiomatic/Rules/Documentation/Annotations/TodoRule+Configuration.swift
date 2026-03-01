struct TodoConfiguration: SeverityBasedRuleOptions {
  enum TodoKeyword: String, AcceptableByConfigurationElement, CaseIterable {
    case todo = "TODO"
    case fixme = "FIXME"
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "only")
  private(set) var only = TodoKeyword.allCases
  typealias Parent = TodoRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$only.key] {
      try only.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
