struct IdentifierNameConfiguration: RuleConfiguration {
  private static let defaultOperators = [
    "/", "=", "-", "+", "!", "*", "|", "^", "~", "?", ".", "%", "<", ">", "&",
  ]

  @ConfigurationElement(isInline: true)
  private(set) var nameConfiguration = NameConfiguration<Parent>(
    minLengthWarning: 3,
    minLengthError: 2,
    maxLengthWarning: 40,
    maxLengthError: 60,
    excluded: ["id"],
  )

  @ConfigurationElement(
    key: "additional_operators", postprocessor: { $0.formUnion(Self.defaultOperators) },
  )
  private(set) var additionalOperators = Set<String>()
  typealias Parent = IdentifierNameRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    do {
      try nameConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    if let value = configuration[$additionalOperators.key] {
      try additionalOperators.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
