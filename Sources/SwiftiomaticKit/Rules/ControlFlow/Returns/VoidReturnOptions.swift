import SwiftiomaticSyntax

struct VoidReturnOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)

  /// When `true` (default), prefer `Void` over `()` in return types and type aliases.
  /// When `false`, prefer `()` over `Void`.
  @OptionElement(key: "use_void")
  private(set) var useVoid = true

  typealias Parent = VoidReturnRule

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$useVoid.key] {
      try useVoid.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
