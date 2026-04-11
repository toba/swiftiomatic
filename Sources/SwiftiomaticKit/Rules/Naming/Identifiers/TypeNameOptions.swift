struct TypeNameOptions: RuleOptions {
  @OptionElement(isInline: true)
  private(set) var nameConfiguration = NameOptions<Parent>(
    minLengthWarning: 3,
    minLengthError: 0,
    maxLengthWarning: 40,
    maxLengthError: 1000,
  )
  @OptionElement(key: "validate_protocols")
  private(set) var validateProtocols = true
  typealias Parent = TypeNameRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try nameConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue
      where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier)
    {
      // Acceptable. Continue.
    }
    if let value = configuration[$validateProtocols.key] {
      try validateProtocols.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
