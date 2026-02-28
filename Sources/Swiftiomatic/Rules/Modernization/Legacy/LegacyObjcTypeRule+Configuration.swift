struct LegacyObjcTypeConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>.warning
  @ConfigurationElement(key: "allowed_types")
  private(set) var allowedTypes: Set<String> = []
  typealias Parent = LegacyObjcTypeRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowedTypes.key] {
      try allowedTypes.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
