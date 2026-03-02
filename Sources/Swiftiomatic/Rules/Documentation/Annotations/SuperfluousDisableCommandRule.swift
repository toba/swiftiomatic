struct SuperfluousDisableCommandRule: SyntaxOnlyRule, Sendable {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SuperfluousDisableCommandConfiguration()

  func validate(file _: SwiftSource) -> [RuleViolation] {
    // This rule is implemented in Linter.swift
    []
  }

  func reason(forRuleIdentifier ruleIdentifier: String) -> String {
    """
    Rule '\(ruleIdentifier)' did not trigger a violation in the disabled region; \
    remove the disable command
    """
  }

  func reason(forNonExistentRule rule: String) -> String {
    "'\(rule)' is not a valid rule; remove it from the disable command"
  }
}
