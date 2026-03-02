import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct SwitchCaseAlignmentRuleTests {
  @Test func switchCaseAlignmentWithoutIndentedCases() async {
    let examples = SwitchCaseAlignmentConfiguration.Examples(indentedCases: false)

    let testExamples = TestExamples(from: SwitchCaseAlignmentRule.configuration)
      .with(
        nonTriggeringExamples: examples.nonTriggeringExamples,
        triggeringExamples: examples.triggeringExamples,
      )

    await verifyRule(testExamples)
  }

  @Test func switchCaseAlignmentWithIndentedCases() async {
    let examples = SwitchCaseAlignmentConfiguration.Examples(indentedCases: true)

    let testExamples = TestExamples(from: SwitchCaseAlignmentRule.configuration)
      .with(
        nonTriggeringExamples: examples.nonTriggeringExamples,
        triggeringExamples: examples.triggeringExamples,
      )

    await verifyRule(testExamples, ruleConfiguration: ["indented_cases": true])
  }
}
