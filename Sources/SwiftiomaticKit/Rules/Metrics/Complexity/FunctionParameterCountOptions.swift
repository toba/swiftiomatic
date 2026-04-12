import SwiftiomaticSyntax

struct FunctionParameterCountOptions: RuleOptions {
  @OptionElement(isInline: true)
  var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 5,
    error: 8,
  )
  @OptionElement(key: "ignores_default_parameters")
  private(set) var ignoresDefaultParameters = true
  typealias Parent = FunctionParameterCountRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue
      where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier)
    {
      // Acceptable — severity is optional.
    }
    if let value = configuration[$ignoresDefaultParameters.key] {
      try ignoresDefaultParameters.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
