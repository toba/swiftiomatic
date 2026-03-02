struct MultilineParametersOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "allows_single_line")
  private(set) var allowsSingleLine = true
  @OptionElement(key: "max_number_of_single_line_parameters")
  private(set) var maxNumberOfSingleLineParameters: Int?

  // sm:disable:next unneeded_throws_rethrows
  func validate() {
    guard let maxNumberOfSingleLineParameters else {
      return
    }
    guard maxNumberOfSingleLineParameters >= 1 else {
      SwiftiomaticError.inconsistentConfiguration(
        ruleID: Parent.identifier,
        message: "Option '\($maxNumberOfSingleLineParameters.key)' should be >= 1.",
      ).print()
      return
    }

    if maxNumberOfSingleLineParameters > 1, !allowsSingleLine {
      SwiftiomaticError.inconsistentConfiguration(
        ruleID: Parent.identifier,
        message: """
          Option '\($maxNumberOfSingleLineParameters.key)' has no effect when \
          '\($allowsSingleLine.key)' is false.
          """,
      ).print()
    }
  }

  typealias Parent = MultilineParametersRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowsSingleLine.key] {
      try allowsSingleLine.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$maxNumberOfSingleLineParameters.key] {
      try maxNumberOfSingleLineParameters.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
