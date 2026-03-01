struct CyclomaticComplexityConfiguration: RuleConfiguration {
  @ConfigurationElement(isInline: true)
  private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 10, error: 20)
  @ConfigurationElement(key: "ignores_case_statements")
  private(set) var ignoresCaseStatements = false

  var params: [RuleParameter<Int>] {
    length.params
  }

  typealias Parent = CyclomaticComplexityRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try length.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    if let value = configuration[$ignoresCaseStatements.key] {
      try ignoresCaseStatements.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
