struct UnusedDeclarationOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>.error
  @OptionElement(key: "include_public_and_open")
  private(set) var includePublicAndOpen = false
  @OptionElement(
    key: "related_usrs_to_skip",
    postprocessor: { $0.insert("s:7SwiftUI15PreviewProviderP") },
  )
  private(set) var relatedUSRsToSkip = Set<String>()
  typealias Parent = UnusedDeclarationRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$includePublicAndOpen.key] {
      try includePublicAndOpen.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$relatedUSRsToSkip.key] {
      try relatedUSRsToSkip.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
