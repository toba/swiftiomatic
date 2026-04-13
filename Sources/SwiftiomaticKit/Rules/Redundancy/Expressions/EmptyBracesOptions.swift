import SwiftiomaticSyntax

struct EmptyBracesOptions: SeverityBasedRuleOptions {
  enum Style: String, AcceptableByOptionElement {
    case noSpace = "no_space"
    case spaced
    case linebreak
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)

  @OptionElement(key: "style")
  private(set) var style: Style = .noSpace

  typealias Parent = EmptyBracesRule

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$style.key] {
      try style.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
