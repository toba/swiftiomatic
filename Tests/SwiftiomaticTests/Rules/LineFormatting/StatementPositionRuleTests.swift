import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct StatementPositionRuleTests {
  @Test(.disabled("requires sourcekitd")) func statementPositionUncuddled() async {
    let configuration = ["statement_mode": "uncuddled_else"]
    let uncuddled = StatementPositionConfiguration.UncuddledExamples()
    let examples = TestExamples(from: StatementPositionRule.configuration)
      .with(
        nonTriggeringExamples: uncuddled.nonTriggeringExamples,
        triggeringExamples: uncuddled.triggeringExamples,
        corrections: uncuddled.corrections,
      )
    await verifyRule(examples, ruleConfiguration: configuration)
  }
}
