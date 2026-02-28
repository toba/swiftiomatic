struct FileLengthConfiguration: RuleConfiguration {
  @ConfigurationElement(inline: true)
  private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 400, error: 1000,
  )
  @ConfigurationElement(key: "ignore_comment_only_lines")
  private(set) var ignoreCommentOnlyLines = false
  typealias Parent = FileLengthRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $ignoreCommentOnlyLines.key.isEmpty {
      $ignoreCommentOnlyLines.key = "ignore_comment_only_lines"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$ignoreCommentOnlyLines.key] {
      try ignoreCommentOnlyLines.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
