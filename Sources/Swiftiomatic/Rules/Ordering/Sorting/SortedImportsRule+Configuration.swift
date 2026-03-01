struct SortedImportsConfiguration: SeverityBasedRuleOptions {
  enum Grouping: String, AcceptableByConfigurationElement {
    /// Sorts import lines based on any import attributes (e.g. `@testable`, `@_exported`, etc.), followed by a case
    /// insensitive comparison of the imported module name.
    case attributes
    /// Sorts import lines based on a case insensitive comparison of the imported module name.
    case names
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "grouping")
  private(set) var grouping = Grouping.names
  typealias Parent = SortedImportsRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$grouping.key] {
      try grouping.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
