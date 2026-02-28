struct PreferKeyPathConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "restrict_to_standard_functions")
  private(set) var restrictToStandardFunctions = true
  @ConfigurationElement(key: "ignore_identity_closures")
  private(set) var ignoreIdentityClosures = false
  typealias Parent = PreferKeyPathRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$restrictToStandardFunctions.key] {
      try restrictToStandardFunctions.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoreIdentityClosures.key] {
      try ignoreIdentityClosures.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
