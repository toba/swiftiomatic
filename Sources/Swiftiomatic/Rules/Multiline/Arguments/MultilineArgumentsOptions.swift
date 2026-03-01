struct MultilineArgumentsOptions: SeverityBasedRuleOptions {
  enum FirstArgumentLocation: String, AcceptableByOptionElement {
    case anyLine = "any_line"
    case sameLine = "same_line"
    case nextLine = "next_line"
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "first_argument_location")
  private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
  @OptionElement(key: "only_enforce_after_first_closure_on_first_line")
  private(set) var onlyEnforceAfterFirstClosureOnFirstLine = false
  typealias Parent = MultilineArgumentsRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    if $onlyEnforceAfterFirstClosureOnFirstLine.key.isEmpty {
      $onlyEnforceAfterFirstClosureOnFirstLine.key =
        "only_enforce_after_first_closure_on_first_line"
    }
    try applySeverityIfPresent(configuration)
    if let value = configuration[$firstArgumentLocation.key] {
      try firstArgumentLocation.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$onlyEnforceAfterFirstClosureOnFirstLine.key] {
      try onlyEnforceAfterFirstClosureOnFirstLine.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
