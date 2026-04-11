struct AssignmentWrappingOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)

  @OptionElement(key: "max_width")
  private(set) var maxWidth = 120

  @OptionElement(key: "indent_width")
  private(set) var indentWidth = 4

  typealias Parent = AssignmentWrappingRule

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$maxWidth.key] {
      try maxWidth.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$indentWidth.key] {
      try indentWidth.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
