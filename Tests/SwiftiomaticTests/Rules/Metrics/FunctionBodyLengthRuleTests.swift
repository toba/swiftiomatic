import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct FunctionBodyLengthRuleTests {
  @Test func warning() async throws {
    let example = Example(
      """
      func f() {
          let x = 0
          let y = 1
          let z = 2
      }
      """,
    )

    #expect(
      try await ruleViolations(
        example,
        rule: FunctionBodyLengthRule.identifier,
        configuration: ["warning": 2, "error": 4],
      ) == [
        RuleViolation(
          ruleType: FunctionBodyLengthRule.self,
          severity: .warning,
          location: Location(file: nil, line: 1, column: 1),
          reason: """
            Function body should span 2 lines or less excluding comments and \
            whitespace: currently spans 3 lines
            """,
        )
      ],
    )
  }

  @Test func error() async throws {
    let example = Example(
      """
      func f() {
          let x = 0
          let y = 1
          let z = 2
      }
      """,
    )

    #expect(
      try await ruleViolations(
        example,
        rule: FunctionBodyLengthRule.identifier,
        configuration: ["warning": 1, "error": 2],
      ) == [
        RuleViolation(
          ruleType: FunctionBodyLengthRule.self,
          severity: .error,
          location: Location(file: nil, line: 1, column: 1),
          reason: """
            Function body should span 2 lines or less excluding comments and \
            whitespace: currently spans 3 lines
            """,
        )
      ],
    )
  }

  @Test func violationMessages() async throws {
    var allViolations: [RuleViolation] = []
    for example in FunctionBodyLengthRule.triggeringExamples {
      try await allViolations.append(
        contentsOf: ruleViolations(
          example,
          rule: FunctionBodyLengthRule.identifier,
          configuration: ["warning": 2],
        ))
    }
    let types = allViolations.compactMap {
      $0.reason.text.split(separator: " ", maxSplits: 1).first
    }

    #expect(
      types == [
        "Function", "Deinitializer", "Initializer", "Subscript", "Accessor", "Accessor",
        "Accessor",
      ],
    )
  }
}
