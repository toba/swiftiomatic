struct InclusiveLanguageConfiguration: SeverityBasedRuleConfiguration {
  private static let defaultTerms: Set<String> = [
    "whitelist",
    "blacklist",
    "master",
    "slave",
  ]

  private static let defaultAllowedTerms: Set<String> = [
    "mastercard"
  ]

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "additional_terms")
  private(set) var additionalTerms: Set<String>?
  @ConfigurationElement(key: "override_terms")
  private(set) var overrideTerms: Set<String>?
  @ConfigurationElement(key: "override_allowed_terms")
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
  mutating func apply(configuration: Any) throws(Issue) {
    if $additionalTerms.key.isEmpty {
      $additionalTerms.key = "additional_terms"
    }
    if $overrideTerms.key.isEmpty {
      $overrideTerms.key = "override_terms"
    }
    if $overrideAllowedTerms.key.isEmpty {
      $overrideAllowedTerms.key = "override_allowed_terms"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$additionalTerms.key] {
      try additionalTerms.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$overrideTerms.key] {
      try overrideTerms.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$overrideAllowedTerms.key] {
      try overrideAllowedTerms.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
