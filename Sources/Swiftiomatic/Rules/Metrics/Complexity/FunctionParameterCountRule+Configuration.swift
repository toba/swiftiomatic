struct FunctionParameterCountConfiguration: RuleConfiguration {
  @ConfigurationElement(isInline: true)
  var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 5,
    error: 8,
  )
  @ConfigurationElement(key: "ignores_default_parameters")
  private(set) var ignoresDefaultParameters = true
  typealias Parent = FunctionParameterCountRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable — severity is optional.
    }
    if let value = configuration[$ignoresDefaultParameters.key] {
      try ignoresDefaultParameters.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
