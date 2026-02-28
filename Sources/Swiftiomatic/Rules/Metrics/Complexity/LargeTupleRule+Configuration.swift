struct LargeTupleConfiguration: RuleConfiguration {
  @ConfigurationElement(inline: true)
  var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 2,
    error: 3,
  )
  @ConfigurationElement(key: "ignore_regex")
  private(set) var ignoreRegex = false
  typealias Parent = LargeTupleRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable — severity is optional.
    }
    if let value = configuration[$ignoreRegex.key] {
      try ignoreRegex.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
