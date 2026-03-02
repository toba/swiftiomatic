import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct BlanketDisableCommandRuleTests {
  private var emptyDescription: TestExamples {
    TestExamples(from: BlanketDisableCommandRule.configuration).with(
      nonTriggeringExamples: [],
      triggeringExamples: [],
    )
  }

  @Test func alwaysBlanketDisable() async {
    let nonTriggeringExamples = [
      Example("// sm:disable file_length\n// sm:enable file_length")
    ]
    await verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))

    let triggeringExamples = [
      Example("// sm:disable file_length\n// sm:enable ↓file_length"),
      Example("// sm:disable:previous ↓file_length"),
      Example("// sm:disable:this ↓file_length"),
      Example("// sm:disable:next ↓file_length"),
    ]
    await verifyRule(
      emptyDescription.with(triggeringExamples: triggeringExamples),
      ruleConfiguration: ["always_blanket_disable": ["file_length"]],
      skipCommentTests: true, skipDisableCommandTests: true,
    )
  }

  @Test func alwaysBlanketDisabledAreAllowed() async {
    let nonTriggeringExamples = [Example("// sm:disable identifier_name\n")]
    await verifyRule(
      emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples),
      ruleConfiguration: ["always_blanket_disable": ["identifier_name"], "allowed_rules": []],
      skipDisableCommandTests: true,
    )
  }

  @Test func allowedRules() async {
    let nonTriggeringExamples = [
      Example("// sm:disable file_length"),
      Example("// sm:disable single_test_class"),
    ]
    await verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))
  }
}
