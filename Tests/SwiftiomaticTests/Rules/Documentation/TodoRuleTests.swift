import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct TodoRuleTests {
  @Test func todo() async {
    await verifyRule(TodoRule.self, commentDoesNotViolate: false)
  }

  @Test func todoMessage() async throws {
    let example = Example("fatalError() // TODO: Implement")
    let allViolations = try await ruleViolations(example, rule: TodoRule.identifier)
    #expect(allViolations.count == 1)
    #expect(allViolations.first?.reason == "TODOs should be resolved (Implement)")
  }

  @Test func fixMeMessage() async throws {
    let example = Example("fatalError() // FIXME: Implement")
    let allViolations = try await ruleViolations(example, rule: TodoRule.identifier)
    #expect(allViolations.count == 1)
    #expect(allViolations.first?.reason == "FIXMEs should be resolved (Implement)")
  }

  @Test func onlyFixMe() async throws {
    let example = Example(
      """
          fatalError() // TODO: Implement todo
          fatalError() // FIXME: Implement fixme
      """,
    )
    let allViolations = try await ruleViolations(example, rule: TodoRule.identifier, configuration: ["only": ["FIXME"]])
    #expect(allViolations.count == 1)
    #expect(allViolations.first?.reason == "FIXMEs should be resolved (Implement fixme)")
  }

  @Test func onlyTodo() async throws {
    let example = Example(
      """
          fatalError() // TODO: Implement todo
          fatalError() // FIXME: Implement fixme
      """,
    )
    let allViolations = try await ruleViolations(example, rule: TodoRule.identifier, configuration: ["only": ["TODO"]])
    #expect(allViolations.count == 1)
    #expect(allViolations.first?.reason == "TODOs should be resolved (Implement todo)")
  }
}
