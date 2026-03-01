import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct RulesTests {
    @Test func leadingWhitespace() async {
        await verifyRule(
            LeadingWhitespaceRule.description, skipDisableCommandTests: true,
            testMultiByteOffsets: false, testShebang: false,
        )
    }

    @Test func mark() async {
        await verifyRule(MarkRule.description, skipCommentTests: true)
    }

    @Test func requiredEnumCase() async {
        let configuration = ["NetworkResponsable": ["notConnected": "error"]]
        await verifyRule(RequiredEnumCaseRule.description, ruleConfiguration: configuration)
    }

    @Test func trailingNewline() async {
        await verifyRule(
            TrailingNewlineRule.description, commentDoesNotViolate: false,
            stringDoesNotViolate: false,
        )
    }

    @Test func orphanedDocComment() async {
        await verifyRule(
            OrphanedDocCommentRule.description, commentDoesNotViolate: false, skipCommentTests: true,
        )
    }
}
