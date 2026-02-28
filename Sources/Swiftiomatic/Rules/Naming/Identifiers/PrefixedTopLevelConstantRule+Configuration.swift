struct PrefixedTopLevelConstantConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "only_private")
  private(set) var onlyPrivateMembers = false
  typealias Parent = PrefixedTopLevelConstantRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$onlyPrivateMembers.key] {
      try onlyPrivateMembers.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
