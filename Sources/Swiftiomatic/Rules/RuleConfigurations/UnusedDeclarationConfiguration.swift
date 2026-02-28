struct UnusedDeclarationConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>.error
  @ConfigurationElement(key: "include_public_and_open")
  private(set) var includePublicAndOpen = false
  @ConfigurationElement(
    key: "related_usrs_to_skip",
    postprocessor: { $0.insert("s:7SwiftUI15PreviewProviderP") },
  )
  private(set) var relatedUSRsToSkip = Set<String>()
  typealias Parent = UnusedDeclarationRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $includePublicAndOpen.key.isEmpty {
      $includePublicAndOpen.key = "include_public_and_open"
    }
    if $relatedUSRsToSkip.key.isEmpty {
      $relatedUSRsToSkip.key = "related_usrs_to_skip"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$includePublicAndOpen.key] {
      try includePublicAndOpen.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$relatedUSRsToSkip.key] {
      try relatedUSRsToSkip.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
