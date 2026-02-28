import Testing

@testable import Swiftiomatic

@Suite struct TodoRuleTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  @Test func todo() {
    verifyRule(TodoRule.description, commentDoesntViolate: false)
  }

  @Test func todoMessage() {
    let example = Example("fatalError() // TODO: Implement")
    let allViolations = violations(example)
    #expect(allViolations.count == 1)
    #expect(allViolations.first!.reason == "TODOs should be resolved (Implement)")
  }

  @Test func fixMeMessage() {
    let example = Example("fatalError() // FIXME: Implement")
    let allViolations = violations(example)
    #expect(allViolations.count == 1)
    #expect(allViolations.first!.reason == "FIXMEs should be resolved (Implement)")
  }

  @Test func onlyFixMe() {
    let example = Example(
      """
          fatalError() // TODO: Implement todo
          fatalError() // FIXME: Implement fixme
      """)
    let allViolations = violations(example, config: ["only": ["FIXME"]])
    #expect(allViolations.count == 1)
    #expect(allViolations.first!.reason == "FIXMEs should be resolved (Implement fixme)")
  }

  @Test func onlyTodo() {
    let example = Example(
      """
          fatalError() // TODO: Implement todo
          fatalError() // FIXME: Implement fixme
      """)
    let allViolations = violations(example, config: ["only": ["TODO"]])
    #expect(allViolations.count == 1)
    #expect(allViolations.first!.reason == "TODOs should be resolved (Implement todo)")
  }

  private func violations(_ example: Example, config: Any? = nil) -> [StyleViolation] {
    let config = makeConfig(config, TodoRule.identifier)!
    return SwiftiomaticTests.violations(example, config: config)
  }
}
