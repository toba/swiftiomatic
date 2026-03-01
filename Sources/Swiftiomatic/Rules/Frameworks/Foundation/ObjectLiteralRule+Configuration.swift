typealias DiscouragedObjectLiteralConfiguration = ObjectLiteralConfiguration<
  DiscouragedObjectLiteralRule,
>

struct ObjectLiteralConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "image_literal")
  private(set) var imageLiteral = true
  @ConfigurationElement(key: "color_literal")
  private(set) var colorLiteral = true
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$imageLiteral.key] {
      try imageLiteral.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$colorLiteral.key] {
      try colorLiteral.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
