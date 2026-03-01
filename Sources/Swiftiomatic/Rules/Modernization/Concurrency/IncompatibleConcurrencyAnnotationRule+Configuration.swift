struct IncompatibleConcurrencyAnnotationConfiguration: SeverityBasedRuleOptions {
  // sm:disable:previous type_name

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "global_actors", postprocessor: { $0.insert("MainActor") })
  private(set) var globalActors = Set<String>()
  typealias Parent = IncompatibleConcurrencyAnnotationRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$globalActors.key] {
      try globalActors.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
