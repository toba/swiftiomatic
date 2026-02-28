struct UnneededOverrideConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "affect_initializers")
  private(set) var affectInits = false
  @ConfigurationElement(key: "excluded_methods")
  private(set) var excludedMethods = Set<String>()
  typealias Parent = UnneededOverrideRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$affectInits.key] {
      try affectInits.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$excludedMethods.key] {
      try excludedMethods.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
