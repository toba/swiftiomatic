import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct ValidateTestCasesRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: ValidateTestCasesRule.self),
      config: makeConfig(nil, ValidateTestCasesRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func methodWithAssertionsMissingTestPrefixTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class FooTests: XCTestCase {
          func example() {
            XCTAssertTrue(true)
          }
        }
        """
      ),
      rule: ValidateTestCasesRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func methodWithTestPrefixDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class FooTests: XCTestCase {
          func testExample() {
            XCTAssertTrue(true)
          }
        }
        """
      ),
      rule: ValidateTestCasesRule.identifier,
    )
    #expect(violations.isEmpty)
  }

  @Test func privateHelperDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class FooTests: XCTestCase {
          private func helper() {
            XCTAssertTrue(true)
          }
        }
        """
      ),
      rule: ValidateTestCasesRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
