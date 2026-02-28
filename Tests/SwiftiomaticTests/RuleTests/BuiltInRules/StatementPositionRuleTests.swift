import Testing
@testable import Swiftiomatic

@Suite struct StatementPositionRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func statementPositionUncuddled() {
        let configuration = ["statement_mode": "uncuddled_else"]
        verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }
}
