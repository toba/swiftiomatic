import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct NoGuardInTestsRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: NoGuardInTestsRule.self),
      config: makeConfig(nil, NoGuardInTestsRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func guardInTestMethodTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            guard let value = optional else { return }
            print(value)
          }
        }
        """
      ),
      rule: NoGuardInTestsRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func guardOutsideTestDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        func notInTestClass() {
          guard let value = optional else { return }
        }
        """
      ),
      rule: NoGuardInTestsRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
