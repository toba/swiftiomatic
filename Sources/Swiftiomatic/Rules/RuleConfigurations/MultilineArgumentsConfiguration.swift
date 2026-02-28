struct MultilineArgumentsConfiguration: SeverityBasedRuleConfiguration {
  enum FirstArgumentLocation: String, AcceptableByConfigurationElement {
    case anyLine = "any_line"
    case sameLine = "same_line"
    case nextLine = "next_line"
  }

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "first_argument_location")
  private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
  @ConfigurationElement(key: "only_enforce_after_first_closure_on_first_line")
  private(set) var onlyEnforceAfterFirstClosureOnFirstLine = false
  typealias Parent = MultilineArgumentsRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $firstArgumentLocation.key.isEmpty {
      $firstArgumentLocation.key = "first_argument_location"
    }
    if $onlyEnforceAfterFirstClosureOnFirstLine.key.isEmpty {
      $onlyEnforceAfterFirstClosureOnFirstLine.key =
        "only_enforce_after_first_closure_on_first_line"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$firstArgumentLocation.key] {
      try firstArgumentLocation.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$onlyEnforceAfterFirstClosureOnFirstLine.key] {
      try onlyEnforceAfterFirstClosureOnFirstLine.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
