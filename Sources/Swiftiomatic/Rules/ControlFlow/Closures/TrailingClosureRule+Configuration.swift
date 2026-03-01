struct TrailingClosureConfiguration: SeverityBasedRuleOptions {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "only_single_muted_parameter")
  private(set) var onlySingleMutedParameter = false
  typealias Parent = TrailingClosureRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$onlySingleMutedParameter.key] {
      try onlySingleMutedParameter.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
