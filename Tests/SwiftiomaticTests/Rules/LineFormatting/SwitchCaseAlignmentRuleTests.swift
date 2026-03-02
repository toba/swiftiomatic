import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct SwitchCaseAlignmentRuleTests {
  @Test func switchCaseAlignmentWithoutIndentedCases() async {
    let baseDescription = SwitchCaseAlignmentRule.description
    let examples = SwitchCaseAlignmentConfiguration.Examples(indentedCases: false)

    let description = baseDescription.with(
      nonTriggeringExamples: examples.nonTriggeringExamples,
      triggeringExamples: examples.triggeringExamples,
    )

    await verifyRule(description)
  }

  @Test func switchCaseAlignmentWithIndentedCases() async {
    let baseDescription = SwitchCaseAlignmentRule.description
    let examples = SwitchCaseAlignmentConfiguration.Examples(indentedCases: true)

    let description = baseDescription.with(
      nonTriggeringExamples: examples.nonTriggeringExamples,
      triggeringExamples: examples.triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["indented_cases": true])
  }
}
