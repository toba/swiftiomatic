import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct RulesTests {
  @Test func leadingWhitespace() async {
    await verifyRule(
      LeadingWhitespaceRule.self, skipDisableCommandTests: true,
      shouldTestMultiByteOffsets: false, testShebang: false,
    )
  }

  @Test func mark() async {
    await verifyRule(MarkRule.self, skipCommentTests: true)
  }

  @Test func requiredEnumCase() async {
    let configuration = ["NetworkResponsable": ["notConnected": "error"]]
    await verifyRule(RequiredEnumCaseRule.self, ruleConfiguration: configuration)
  }

  @Test func trailingNewline() async {
    await verifyRule(
      TrailingNewlineRule.self, commentDoesNotViolate: false,
      stringDoesNotViolate: false,
    )
  }

  @Test func orphanedDocComment() async {
    await verifyRule(
      OrphanedDocCommentRule.self, commentDoesNotViolate: false, skipCommentTests: true,
    )
  }
}
