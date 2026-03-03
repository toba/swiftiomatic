import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct NoForceTryInTestsRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: NoForceTryInTestsRule.self),
      config: makeConfig(nil, NoForceTryInTestsRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func forceTryInTestMethodTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class FooTests: XCTestCase {
          func test_example() {
            try! doSomething()
          }
        }
        """
      ),
      rule: NoForceTryInTestsRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func forceTryOutsideTestDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("try! doSomething()"),
      rule: NoForceTryInTestsRule.identifier,
    )
    #expect(violations.isEmpty)
  }

  @Test func forceTryInNonTestMethodDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class FooTests: XCTestCase {
          func helperMethod() {
            try! doSomething()
          }
        }
        """
      ),
      rule: NoForceTryInTestsRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
