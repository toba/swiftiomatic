import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct StatementPositionRuleTests {
  @Test(.disabled("requires sourcekitd")) func statementPositionUncuddled() async {
    let configuration = ["statement_mode": "uncuddled_else"]
    await verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
  }
}
