import Testing
@testable import Swiftiomatic

@Suite struct RulesTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func leadingWhitespace() {
        verifyRule(
            LeadingWhitespaceRule.description, skipDisableCommandTests: true,
            testMultiByteOffsets: false, testShebang: false,
        )
    }

    @Test func mark() {
        verifyRule(MarkRule.description, skipCommentTests: true)
    }

    @Test func requiredEnumCase() {
        let configuration = ["NetworkResponsable": ["notConnected": "error"]]
        verifyRule(RequiredEnumCaseRule.description, ruleConfiguration: configuration)
    }

    @Test func trailingNewline() {
        verifyRule(
            TrailingNewlineRule.description, commentDoesNotViolate: false,
            stringDoesNotViolate: false,
        )
    }

    @Test func orphanedDocComment() {
        verifyRule(
            OrphanedDocCommentRule.description, commentDoesNotViolate: false, skipCommentTests: true,
        )
    }
}
