struct ForWhereOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "allow_for_as_filter")
  private(set) var allowForAsFilter = false
  typealias Parent = ForWhereRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowForAsFilter.key] {
      try allowForAsFilter.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
