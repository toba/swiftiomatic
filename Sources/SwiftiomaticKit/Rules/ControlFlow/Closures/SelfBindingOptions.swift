import SwiftiomaticSyntax

struct SelfBindingOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "bind_identifier")
  private(set) var bindIdentifier = "self"
  typealias Parent = SelfBindingRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$bindIdentifier.key] {
      try bindIdentifier.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
