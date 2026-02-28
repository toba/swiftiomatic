import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct StatementPositionRuleTests {
    @Test func statementPositionUncuddled() async {
        let configuration = ["statement_mode": "uncuddled_else"]
        await verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }
}
