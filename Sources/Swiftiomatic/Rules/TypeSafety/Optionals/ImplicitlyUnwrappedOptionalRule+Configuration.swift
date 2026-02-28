struct ImplicitlyUnwrappedOptionalConfiguration: SeverityBasedRuleConfiguration {
  enum ImplicitlyUnwrappedOptionalModeConfiguration: String,
    AcceptableByConfigurationElement
  {  // sm:disable:this type_name
    case all
    case allExceptIBOutlets = "all_except_iboutlets"
    case weakExceptIBOutlets = "weak_except_iboutlets"
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>.warning
  @ConfigurationElement(key: "mode")
  private(set) var mode = ImplicitlyUnwrappedOptionalModeConfiguration.allExceptIBOutlets
  typealias Parent = ImplicitlyUnwrappedOptionalRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$mode.key] {
      try mode.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
