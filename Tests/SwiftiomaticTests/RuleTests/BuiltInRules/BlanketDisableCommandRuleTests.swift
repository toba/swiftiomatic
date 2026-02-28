import Testing
@testable import Swiftiomatic

@Suite struct BlanketDisableCommandRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    private var emptyDescription: RuleDescription {
        BlanketDisableCommandRule.description
            .with(triggeringExamples: [])
            .with(nonTriggeringExamples: [])
    }

    @Test func alwaysBlanketDisable() {
        let nonTriggeringExamples = [
            Example("// swiftlint:disable file_length\n// swiftlint:enable file_length"),
        ]
        verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))

        let triggeringExamples = [
            Example("// swiftlint:disable file_length\n// swiftlint:enable ↓file_length"),
            Example("// swiftlint:disable:previous ↓file_length"),
            Example("// swiftlint:disable:this ↓file_length"),
            Example("// swiftlint:disable:next ↓file_length"),
        ]
        verifyRule(
            emptyDescription.with(triggeringExamples: triggeringExamples),
            ruleConfiguration: ["always_blanket_disable": ["file_length"]],
            skipCommentTests: true, skipDisableCommandTests: true,
        )
    }

    @Test func alwaysBlanketDisabledAreAllowed() {
        let nonTriggeringExamples = [Example("// swiftlint:disable identifier_name\n")]
        verifyRule(
            emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples),
            ruleConfiguration: ["always_blanket_disable": ["identifier_name"], "allowed_rules": []],
            skipDisableCommandTests: true,
        )
    }

    @Test func allowedRules() {
        let nonTriggeringExamples = [
            Example("// swiftlint:disable file_length"),
            Example("// swiftlint:disable single_test_class"),
        ]
        verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))
    }
}
