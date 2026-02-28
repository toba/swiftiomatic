struct MultilineCallArgumentsConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "allows_single_line")
  private(set) var allowsSingleLine = true
  @ConfigurationElement(key: "max_number_of_single_line_parameters")
  private(set) var maxNumberOfSingleLineParameters: Int?

  func validate() throws(Issue) {
    guard let maxNumberOfSingleLineParameters else {
      return
    }
    guard maxNumberOfSingleLineParameters >= 1 else {
      throw Issue.inconsistentConfiguration(
        ruleID: Parent.identifier,
        message: "Option '\($maxNumberOfSingleLineParameters.key)' should be >= 1.",
      )
    }

    if maxNumberOfSingleLineParameters > 1, !allowsSingleLine {
      throw Issue.inconsistentConfiguration(
        ruleID: Parent.identifier,
        message: """
          Option '\($maxNumberOfSingleLineParameters.key)' has no effect when \
          '\($allowsSingleLine.key)' is false.
          """,
      )
    }
  }

  typealias Parent = MultilineCallArgumentsRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowsSingleLine.key] {
      try allowsSingleLine.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$maxNumberOfSingleLineParameters.key] {
      try maxNumberOfSingleLineParameters.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
