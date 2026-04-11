import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct NoForceUnwrapInTestsRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: NoForceUnwrapInTestsRule.self),
      config: makeConfig(nil, NoForceUnwrapInTestsRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func forceUnwrapInTestMethodTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            let value = optional!
          }
        }
        """
      ),
      rule: NoForceUnwrapInTestsRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func forceUnwrapOutsideTestDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("let value = optional!"),
      rule: NoForceUnwrapInTestsRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
