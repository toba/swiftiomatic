struct NonOverridableClassDeclarationConfiguration: SeverityBasedRuleConfiguration {
  enum FinalClassModifier: String, AcceptableByConfigurationElement {
    case finalClass = "final class"
    case `static`
  }

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
  @ConfigurationElement(key: "final_class_modifier")
  private(set) var finalClassModifier = FinalClassModifier.finalClass
  typealias Parent = NonOverridableClassDeclarationRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $finalClassModifier.key.isEmpty {
      $finalClassModifier.key = "final_class_modifier"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$finalClassModifier.key] {
      try finalClassModifier.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
