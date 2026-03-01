struct PrivateOutletOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "allow_private_set")
  private(set) var allowPrivateSet = false
  typealias Parent = PrivateOutletRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowPrivateSet.key] {
      try allowPrivateSet.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
