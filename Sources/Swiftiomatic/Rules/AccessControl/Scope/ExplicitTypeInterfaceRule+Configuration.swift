struct ExplicitTypeInterfaceConfiguration: SeverityBasedRuleConfiguration {
  enum VariableKind: String, AcceptableByConfigurationElement, CaseIterable {
    case instance
    case local
    case `static`
    case `class`

    static let all = Set(allCases)
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "excluded")
  private(set) var excluded = [VariableKind]()
  @ConfigurationElement(key: "allow_redundancy")
  private(set) var allowRedundancy = false

  var allowedKinds: Set<VariableKind> {
    VariableKind.all.subtracting(excluded)
  }

  typealias Parent = ExplicitTypeInterfaceRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$excluded.key] {
      try excluded.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$allowRedundancy.key] {
      try allowRedundancy.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
