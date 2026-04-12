import SwiftiomaticSyntax

struct ImplicitOptionalInitializationOptions: SeverityBasedRuleOptions {  // sm:disable:this type_name
  enum Style: String, AcceptableByOptionElement {
    case always
    case never
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "style")
  private(set) var style: Style = .always
  typealias Parent = ImplicitOptionalInitializationRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$style.key] {
      try style.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
