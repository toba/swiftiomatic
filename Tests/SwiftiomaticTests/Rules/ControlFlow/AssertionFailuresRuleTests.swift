import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct AssertionFailuresRuleTests {
  @Test func allExamples() async {
    await verifyRule(AssertionFailuresRule.self)
  }

  @Test func assertFalseTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example("assert(false)"),
      rule: AssertionFailuresRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func preconditionFalseTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example("precondition(false)"),
      rule: AssertionFailuresRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func assertTrueDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("assert(true)"),
      rule: AssertionFailuresRule.identifier,
    )
    #expect(violations.isEmpty)
  }

  @Test func assertWithExpressionDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("assert(false || true)"),
      rule: AssertionFailuresRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
