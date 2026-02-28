struct PreferKeyPathConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "restrict_to_standard_functions")
  private(set) var restrictToStandardFunctions = true
  @ConfigurationElement(key: "ignore_identity_closures")
  private(set) var ignoreIdentityClosures = false
  typealias Parent = PreferKeyPathRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $restrictToStandardFunctions.key.isEmpty {
      $restrictToStandardFunctions.key = "restrict_to_standard_functions"
    }
    if $ignoreIdentityClosures.key.isEmpty {
      $ignoreIdentityClosures.key = "ignore_identity_closures"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$restrictToStandardFunctions.key] {
      try restrictToStandardFunctions.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$ignoreIdentityClosures.key] {
      try ignoreIdentityClosures.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
