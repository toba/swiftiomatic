struct SuperfluousDisableCommandRule: SyntaxOnlyRule, Sendable {
    static let id = "superfluous_disable_command"
    static let name = "Superfluous Disable Command"
    static let summary = ""
    static var nonTriggeringExamples: [Example] {
        [
              Example("let abc:Void // sm:disable:this colon"),
              Example(
                """
                // sm:disable colon
                let abc:Void
                // sm:enable colon
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("let abc: Void // sm:disable:this colon"),
              Example(
                """
                // sm:disable colon
                let abc: Void
                // sm:enable colon
                """,
              ),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

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
