struct FileNameNoSpaceConfiguration: SeverityBasedRuleOptions {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>.warning
  @ConfigurationElement(key: "excluded")
  private(set) var excluded = Set<String>()
  typealias Parent = FileNameNoSpaceRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$excluded.key] {
      try excluded.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
