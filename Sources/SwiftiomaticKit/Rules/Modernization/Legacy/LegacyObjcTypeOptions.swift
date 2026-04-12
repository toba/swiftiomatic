import SwiftiomaticSyntax

struct LegacyObjcTypeOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>.warning
  @OptionElement(key: "allowed_types")
  private(set) var allowedTypes: Set<String> = []
  typealias Parent = LegacyObjcTypeRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$allowedTypes.key] {
      try allowedTypes.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
