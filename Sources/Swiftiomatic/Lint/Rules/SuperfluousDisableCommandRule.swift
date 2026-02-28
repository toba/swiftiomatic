struct SuperfluousDisableCommandRule: SourceKitFreeRule, Sendable {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "superfluous_disable_command",
        name: "Superfluous Disable Command",
        description: """
        'disable' commands are superfluous when the disabled rule would not have triggered a violation \
        in the disabled region. Use " - " if you wish to document a command.
        """,
        kind: .lint,
        nonTriggeringExamples: [
            Example("let abc:Void // sm:disable:this colon"),
            Example(
                """
                // sm:disable colon
                let abc:Void
                // sm:enable colon
                """,
            ),
        ],
        triggeringExamples: [
            Example("let abc: Void // sm:disable:this colon"),
            Example(
                """
                // sm:disable colon
                let abc: Void
                // sm:enable colon
                """,
            ),
        ],
    )

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
