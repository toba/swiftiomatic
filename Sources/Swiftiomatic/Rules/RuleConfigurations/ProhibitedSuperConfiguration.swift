struct ProhibitedSuperConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "excluded")
  private(set) var excluded = [String]()
  @ConfigurationElement(key: "included")
  private(set) var included = ["*"]

  private static let methodNames = [
    // NSFileProviderExtension
    "providePlaceholder(at:completionHandler:)",
    // NSTextInput
    "doCommand(by:)",
    // NSView
    "updateLayer()",
    // UIViewController
    "loadView()",
  ]

  var resolvedMethodNames: [String] {
    var names = [String]()
    if included.contains("*"), !excluded.contains("*") {
      names += Self.methodNames
    }
    names += included.filter { $0 != "*" }
    names = names.filter { !excluded.contains($0) }
    return names
  }

  typealias Parent = ProhibitedSuperRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $excluded.key.isEmpty {
      $excluded.key = "excluded"
    }
    if $included.key.isEmpty {
      $included.key = "included"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$excluded.key] {
      try excluded.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$included.key] {
      try included.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
