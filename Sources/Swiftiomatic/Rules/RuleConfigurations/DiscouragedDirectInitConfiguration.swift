struct DiscouragedDirectInitConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)

  @ConfigurationElement(
    key: "types",
    postprocessor: { $0.formUnion($0.map { name in "\(name).init" }) },
  )
  private(set) var discouragedInits: Set = [
    "Bundle",
    "NSError",
    "UIDevice",
  ]
  typealias Parent = DiscouragedDirectInitRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $discouragedInits.key.isEmpty {
      $discouragedInits.key = "types"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$discouragedInits.key] {
      try discouragedInits.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
