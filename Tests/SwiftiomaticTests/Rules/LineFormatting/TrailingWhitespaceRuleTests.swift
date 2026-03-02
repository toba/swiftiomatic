import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct TrailingWhitespaceRuleTests {
  @Test func withIgnoresEmptyLinesEnabled() async {
    // Perform additional tests with the ignores_empty_lines setting enabled.
    // The set of non-triggering examples is extended by a whitespace-indented empty line
    let baseExamples = TestExamples(from: TrailingWhitespaceRule.self)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples + [Example(" \n")]
    let description = baseExamples.with(nonTriggeringExamples: nonTriggeringExamples)

    await verifyRule(
      description,
      ruleConfiguration: ["ignores_empty_lines": true, "ignores_comments": true],
    )
  }

  @Test func withIgnoresCommentsDisabled() async {
    // Perform additional tests with the ignores_comments settings disabled.
    let baseExamples = TestExamples(from: TrailingWhitespaceRule.self)
    let triggeringComments = [
      Example("// \n"),
      Example("let name: String // \n"),
    ]
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples
      .filter { !triggeringComments.contains($0) }
    let triggeringExamples = baseExamples.triggeringExamples + triggeringComments
    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )
    await verifyRule(
      description,
      ruleConfiguration: ["ignores_empty_lines": false, "ignores_comments": false],
      commentDoesNotViolate: false,
    )
  }

  @Test func withIgnoresLiteralsEnabled() async {
    // Perform additional tests with the ignores_literals setting enabled.
    // This setting only ignores trailing whitespace inside multiline string literals.
    let baseExamples = TestExamples(from: TrailingWhitespaceRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("let multiline = \"\"\"\n    content   \n    \"\"\"\n")
      ]
    let triggeringExamples =
      baseExamples.triggeringExamples + [
        Example("let codeWithSpace = 123    \n"),
        Example("var number = 42   \n"),
      ]
    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description,
      ruleConfiguration: ["ignores_literals": true],
    )
  }
}
