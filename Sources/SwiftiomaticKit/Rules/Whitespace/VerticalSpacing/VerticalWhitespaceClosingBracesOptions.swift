import SwiftiomaticSyntax

struct VerticalWhitespaceClosingBracesOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "only_enforce_before_trivial_lines")
  private(set) var onlyEnforceBeforeTrivialLines = false
  typealias Parent = VerticalWhitespaceClosingBracesRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$onlyEnforceBeforeTrivialLines.key] {
      try onlyEnforceBeforeTrivialLines.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
