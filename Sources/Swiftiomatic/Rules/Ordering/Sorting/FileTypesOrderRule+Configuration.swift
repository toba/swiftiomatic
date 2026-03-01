struct FileTypesOrderConfiguration: SeverityBasedRuleOptions {
  enum FileType: String, AcceptableByConfigurationElement {
    case supportingType = "supporting_type"
    case mainType = "main_type"
    case `extension`
    case previewProvider = "preview_provider"
    case libraryContentProvider = "library_content_provider"
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "order")
  private(set) var order: [[FileType]] = [
    [.supportingType],
    [.mainType],
    [.extension],
    [.previewProvider],
    [.libraryContentProvider],
  ]
  typealias Parent = FileTypesOrderRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$order.key] {
      try order.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
