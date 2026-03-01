struct PrefixedTopLevelConstantOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "only_private")
  private(set) var onlyPrivateMembers = false
  typealias Parent = PrefixedTopLevelConstantRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$onlyPrivateMembers.key] {
      try onlyPrivateMembers.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
