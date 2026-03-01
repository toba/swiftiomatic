struct RedundantVoidReturnConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "include_closures")
  private(set) var includeClosures = true
  typealias Parent = RedundantVoidReturnRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$includeClosures.key] {
      try includeClosures.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
