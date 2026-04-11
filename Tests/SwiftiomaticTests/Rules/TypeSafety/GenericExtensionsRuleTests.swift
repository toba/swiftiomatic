import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct GenericExtensionsRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: GenericExtensionsRule.self),
      config: makeConfig(nil, GenericExtensionsRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func whereClauseWithSameTypeTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example("extension Array where Element == Foo {}"),
      rule: GenericExtensionsRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func angleBracketSyntaxDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("extension Array<Foo> {}"),
      rule: GenericExtensionsRule.identifier,
    )
    #expect(violations.isEmpty)
  }

  @Test func conformanceConstraintDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example("extension Array where Element: Equatable {}"),
      rule: GenericExtensionsRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
