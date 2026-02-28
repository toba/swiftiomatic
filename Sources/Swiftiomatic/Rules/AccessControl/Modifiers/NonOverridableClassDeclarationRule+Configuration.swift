struct NonOverridableClassDeclarationConfiguration: SeverityBasedRuleConfiguration {
  enum FinalClassModifier: String, AcceptableByConfigurationElement {
    case finalClass = "final class"
    case `static`
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>.warning
  @ConfigurationElement(key: "final_class_modifier")
  private(set) var finalClassModifier = FinalClassModifier.finalClass
  typealias Parent = NonOverridableClassDeclarationRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$finalClassModifier.key] {
      try finalClassModifier.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
