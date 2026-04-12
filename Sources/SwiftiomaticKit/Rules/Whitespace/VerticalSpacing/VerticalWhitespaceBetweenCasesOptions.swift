import SwiftiomaticSyntax

struct VerticalWhitespaceBetweenCasesOptions: SeverityBasedRuleOptions {
  enum SeparationStyle: String, AcceptableByOptionElement {
    case always
    case never
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "separation")
  private(set) var separation: SeparationStyle = .always
  typealias Parent = VerticalWhitespaceBetweenCasesRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$separation.key] {
      try separation.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
