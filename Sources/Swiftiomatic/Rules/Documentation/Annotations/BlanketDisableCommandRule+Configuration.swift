struct BlanketDisableCommandConfiguration: SeverityBasedRuleOptions {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "allowed_rules")
  private(set) var allowedRuleIdentifiers: Set<String> = [
    "file_header",
    "file_length",
    "file_name",
    "file_name_no_space",
    "single_test_class",
  ]
  @ConfigurationElement(key: "always_blanket_disable")
  private(set) var alwaysBlanketDisableRuleIdentifiers: Set<String> = []
  typealias Parent = BlanketDisableCommandRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowedRuleIdentifiers.key] {
      try allowedRuleIdentifiers.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysBlanketDisableRuleIdentifiers.key] {
      try alwaysBlanketDisableRuleIdentifiers.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
