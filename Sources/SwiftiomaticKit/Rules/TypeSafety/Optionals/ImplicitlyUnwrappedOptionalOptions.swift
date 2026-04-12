import SwiftiomaticSyntax

struct ImplicitlyUnwrappedOptionalOptions: SeverityBasedRuleOptions {
  enum ImplicitlyUnwrappedOptionalModeConfiguration: String,
    AcceptableByOptionElement
  {  // sm:disable:this type_name
    case all
    case allExceptIBOutlets = "all_except_iboutlets"
    case weakExceptIBOutlets = "weak_except_iboutlets"
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>.warning
  @OptionElement(key: "mode")
  private(set) var mode = ImplicitlyUnwrappedOptionalModeConfiguration.allExceptIBOutlets
  typealias Parent = ImplicitlyUnwrappedOptionalRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$mode.key] {
      try mode.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
