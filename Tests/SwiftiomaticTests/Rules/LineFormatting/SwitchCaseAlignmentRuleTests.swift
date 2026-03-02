import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct SwitchCaseAlignmentRuleTests {
  @Test func switchCaseAlignmentWithoutIndentedCases() async {
    let examples = SwitchCaseAlignmentRule.Examples(indentedCases: false)

    let testExamples = TestExamples(from: SwitchCaseAlignmentRule.self)
      .with(
        nonTriggeringExamples: examples.nonTriggeringExamples,
        triggeringExamples: examples.triggeringExamples,
      )

    await verifyRule(testExamples)
  }

  @Test func switchCaseAlignmentWithIndentedCases() async {
    let examples = SwitchCaseAlignmentRule.Examples(indentedCases: true)

    let testExamples = TestExamples(from: SwitchCaseAlignmentRule.self)
      .with(
        nonTriggeringExamples: examples.nonTriggeringExamples,
        triggeringExamples: examples.triggeringExamples,
      )

    await verifyRule(testExamples, ruleConfiguration: ["indented_cases": true])
  }
}
