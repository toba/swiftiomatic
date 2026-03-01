struct FileLengthConfiguration: RuleConfiguration {
  @ConfigurationElement(isInline: true)
  var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 400, error: 1000,
  )
  @ConfigurationElement(key: "ignore_comment_only_lines")
  private(set) var ignoreCommentOnlyLines = false
  typealias Parent = FileLengthRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable — severity is optional.
    }
    if let value = configuration[$ignoreCommentOnlyLines.key] {
      try ignoreCommentOnlyLines.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
