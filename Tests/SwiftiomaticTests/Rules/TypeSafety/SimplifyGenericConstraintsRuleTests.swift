import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct SimplifyGenericConstraintsRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: SimplifyGenericConstraintsRule.self),
      config: makeConfig(nil, SimplifyGenericConstraintsRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func whereClauseSimpleConformanceTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example("func foo<T>(_ value: T) where T: Hashable {}"),
      rule: SimplifyGenericConstraintsRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func inlineConstraintDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("func foo<T: Hashable>(_ value: T) {}"),
      rule: SimplifyGenericConstraintsRule.identifier,
    )
    #expect(violations.isEmpty)
  }

  @Test func associatedTypeConstraintDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("func foo<T>(_ value: T) where T.Element: Equatable {}"),
      rule: SimplifyGenericConstraintsRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
