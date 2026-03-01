struct CollectionAlignmentOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "align_colons")
  private(set) var alignColons = false
  typealias Parent = CollectionAlignmentRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$alignColons.key] {
      try alignColons.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
