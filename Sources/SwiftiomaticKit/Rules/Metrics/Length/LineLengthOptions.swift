struct LineLengthOptions: RuleOptions {
  @OptionElement(isInline: true)
  private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 120, error: 200)
  @OptionElement(key: "ignores_urls")
  private(set) var ignoresURLs = false
  @OptionElement(key: "ignores_function_declarations")
  private(set) var ignoresFunctionDeclarations = false
  @OptionElement(key: "ignores_comments")
  private(set) var ignoresComments = false
  @OptionElement(key: "ignores_interpolated_strings")
  private(set) var ignoresInterpolatedStrings = false
  @OptionElement(key: "ignores_multiline_strings")
  private(set) var ignoresMultilineStrings = false
  @OptionElement(key: "ignores_regex_literals")
  private(set) var ignoresRegexLiterals = false
  @OptionElement(key: "excluded_lines_patterns")
  private(set) var excludedLinesPatterns: Set<String> = []

  var params: [RuleParameter<Int>] {
    length.params
  }

  typealias Parent = LineLengthRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try length.apply(configuration, ruleID: Parent.identifier)
    } catch let issue
      where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier)
    {
      // Acceptable. Continue.
    }
    if let value = configuration[$ignoresURLs.key] {
      try ignoresURLs.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoresFunctionDeclarations.key] {
      try ignoresFunctionDeclarations.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoresComments.key] {
      try ignoresComments.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoresInterpolatedStrings.key] {
      try ignoresInterpolatedStrings.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoresMultilineStrings.key] {
      try ignoresMultilineStrings.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoresRegexLiterals.key] {
      try ignoresRegexLiterals.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$excludedLinesPatterns.key] {
      try excludedLinesPatterns.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
