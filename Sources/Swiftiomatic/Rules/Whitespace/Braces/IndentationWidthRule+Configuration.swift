struct IndentationWidthConfiguration: SeverityBasedRuleConfiguration {
  private static let defaultIndentationWidth = 4

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>.warning
  @ConfigurationElement(
    key: "indentation_width",
    postprocessor: {
      if $0 < 1 {
        SwiftiomaticError.invalidConfiguration(ruleID: Parent.identifier).print()
        $0 = Self.defaultIndentationWidth
      }
    },
  )
  private(set) var indentationWidth = 4
  @ConfigurationElement(key: "include_comments")
  private(set) var includeComments = true
  @ConfigurationElement(key: "include_compiler_directives")
  private(set) var includeCompilerDirectives = true
  @ConfigurationElement(key: "include_multiline_strings")
  private(set) var includeMultilineStrings = true
  typealias Parent = IndentationWidthRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$indentationWidth.key] {
      try indentationWidth.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$includeComments.key] {
      try includeComments.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$includeCompilerDirectives.key] {
      try includeCompilerDirectives.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$includeMultilineStrings.key] {
      try includeMultilineStrings.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
