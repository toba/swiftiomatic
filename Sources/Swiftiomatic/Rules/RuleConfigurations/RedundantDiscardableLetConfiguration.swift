struct RedundantDiscardableLetConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "ignore_swiftui_view_bodies")
  private(set) var ignoreSwiftUIViewBodies = false
  typealias Parent = RedundantDiscardableLetRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $ignoreSwiftUIViewBodies.key.isEmpty {
      $ignoreSwiftUIViewBodies.key = "ignore_swiftui_view_bodies"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$ignoreSwiftUIViewBodies.key] {
      try ignoreSwiftUIViewBodies.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
