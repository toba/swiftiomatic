struct RedundantTypeAnnotationConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "ignore_attributes")
  var ignoreAttributes = Set<String>(["IBInspectable"])
  @ConfigurationElement(key: "ignore_properties")
  private(set) var ignoreProperties = false
  @ConfigurationElement(key: "consider_default_literal_types_redundant")
  private(set) var considerDefaultLiteralTypesRedundant = false
  typealias Parent = RedundantTypeAnnotationRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$ignoreAttributes.key] {
      try ignoreAttributes.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoreProperties.key] {
      try ignoreProperties.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$considerDefaultLiteralTypesRedundant.key] {
      try considerDefaultLiteralTypesRedundant.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
