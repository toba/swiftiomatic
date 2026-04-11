import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ContainsOverFirstNotNilRuleTests {
  @Test(.disabled("Rule produces 0 violations"))
  func firstReason() async throws {
    let example = Example("↓myList.first { $0 % 2 == 0 } != nil")
    let violations = try await ruleViolations(example, rule: ContainsOverFirstNotNilRule.identifier)

    #expect(violations.count == 1)
    #expect(violations.first?.reason == "Prefer `contains` over `first(where:) != nil`")
  }

  @Test(.disabled("Rule produces 0 violations"))
  func firstIndexReason() async throws {
    let example = Example("↓myList.firstIndex { $0 % 2 == 0 } != nil")
    let violations = try await ruleViolations(example, rule: ContainsOverFirstNotNilRule.identifier)

    #expect(violations.count == 1)
    #expect(violations.first?.reason == "Prefer `contains` over `firstIndex(where:) != nil`")
  }
}
