import SwiftiomaticSyntax

struct InclusiveLanguageOptions: SeverityBasedRuleOptions {
  private static let defaultTerms: Set<String> = [
    "whitelist",
    "blacklist",
    "master",
    "slave",
  ]

  private static let defaultAllowedTerms: Set<String> = [
    "mastercard"
  ]

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "additional_terms")
  private(set) var additionalTerms: Set<String>?
  @OptionElement(key: "override_terms")
  private(set) var overrideTerms: Set<String>?
  @OptionElement(key: "override_allowed_terms")
  private(set) var overrideAllowedTerms: Set<String>?

  var allTerms: [String] {
    let allTerms = overrideTerms ?? Self.defaultTerms
    return allTerms.union(additionalTerms ?? [])
      .map { $0.lowercased() }
      .unique
      .sorted()
  }

  var allAllowedTerms: Set<String> {
    Set((overrideAllowedTerms ?? Self.defaultAllowedTerms).map { $0.lowercased() })
  }

  typealias Parent = InclusiveLanguageRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$additionalTerms.key] {
      try additionalTerms.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$overrideTerms.key] {
      try overrideTerms.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$overrideAllowedTerms.key] {
      try overrideAllowedTerms.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
