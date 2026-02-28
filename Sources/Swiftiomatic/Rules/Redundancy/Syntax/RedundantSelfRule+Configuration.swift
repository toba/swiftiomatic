struct RedundantSelfConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "keep_in_initializers")
  private(set) var keepInInitializers = false
  @ConfigurationElement(key: "only_in_closures")
  private(set) var onlyInClosures = true
  typealias Parent = RedundantSelfRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$keepInInitializers.key] {
      try keepInInitializers.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$onlyInClosures.key] {
      try onlyInClosures.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
