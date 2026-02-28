struct SortedImportsConfiguration: SeverityBasedRuleConfiguration {
  enum Grouping: String, AcceptableByConfigurationElement {
    /// Sorts import lines based on any import attributes (e.g. `@testable`, `@_exported`, etc.), followed by a case
    /// insensitive comparison of the imported module name.
    case attributes
    /// Sorts import lines based on a case insensitive comparison of the imported module name.
    case names
  }

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "grouping")
  private(set) var grouping = Grouping.names
  typealias Parent = SortedImportsRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $grouping.key.isEmpty {
      $grouping.key = "grouping"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$grouping.key] {
      try grouping.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
