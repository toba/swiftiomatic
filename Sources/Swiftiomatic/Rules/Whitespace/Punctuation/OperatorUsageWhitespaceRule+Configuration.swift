struct OperatorUsageWhitespaceConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "lines_look_around")
  private(set) var linesLookAround = 2
  @ConfigurationElement(key: "skip_aligned_constants")
  private(set) var skipAlignedConstants = true
  @ConfigurationElement(key: "allowed_no_space_operators")
  private(set) var allowedNoSpaceOperators = ["...", "..<"]
  typealias Parent = OperatorUsageWhitespaceRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$linesLookAround.key] {
      try linesLookAround.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$skipAlignedConstants.key] {
      try skipAlignedConstants.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$allowedNoSpaceOperators.key] {
      try allowedNoSpaceOperators.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
