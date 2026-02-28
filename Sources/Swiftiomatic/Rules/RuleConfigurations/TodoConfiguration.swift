struct TodoConfiguration: SeverityBasedRuleConfiguration {
  enum TodoKeyword: String, AcceptableByConfigurationElement, CaseIterable {
    case todo = "TODO"
    case fixme = "FIXME"
  }

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "only")
  private(set) var only = TodoKeyword.allCases
  typealias Parent = TodoRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $only.key.isEmpty {
      $only.key = "only"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$only.key] {
      try only.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
