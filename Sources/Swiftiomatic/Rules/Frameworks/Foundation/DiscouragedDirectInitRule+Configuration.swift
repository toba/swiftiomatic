struct DiscouragedDirectInitConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)

  @ConfigurationElement(
    key: "types",
    postprocessor: { $0.formUnion($0.map { name in "\(name).init" }) },
  )
  private(set) var discouragedInits: Set = [
    "Bundle",
    "NSError",
    "UIDevice",
  ]
  typealias Parent = DiscouragedDirectInitRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$discouragedInits.key] {
      try discouragedInits.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
