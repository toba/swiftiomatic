import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct StatementPositionRuleTests {
  @Test(.disabled("requires sourcekitd")) func statementPositionUncuddled() async {
    let configuration = ["statement_mode": "uncuddled_else"]
    let uncuddled = StatementPositionRule.UncuddledExamples()
    let examples = TestExamples(from: StatementPositionRule.self)
      .with(
        nonTriggeringExamples: uncuddled.nonTriggeringExamples,
        triggeringExamples: uncuddled.triggeringExamples,
        corrections: uncuddled.corrections,
      )
    await verifyRule(examples, ruleConfiguration: configuration)
  }
}
