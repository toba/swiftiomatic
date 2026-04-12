import SwiftiomaticSyntax

struct XCTSpecificMatcherOptions: SeverityBasedRuleOptions {
  enum Matcher: String, AcceptableByOptionElement, CaseIterable {
    case oneArgumentAsserts = "one-argument-asserts"
    case twoArgumentAsserts = "two-argument-asserts"
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "matchers")
  private(set) var matchers = Matcher.allCases
  typealias Parent = XCTSpecificMatcherRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$matchers.key] {
      try matchers.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
