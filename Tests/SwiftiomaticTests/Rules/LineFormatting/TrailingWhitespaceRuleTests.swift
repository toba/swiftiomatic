import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct TrailingWhitespaceRuleTests {
  // MARK: - Non-triggering (default: ignores_comments = true)

  @Test func noTrailingWhitespaceDoesNotTrigger() async {
    await assertNoViolation(TrailingWhitespaceRule.self, "let name: String\n")
  }

  @Test func commentWithoutTrailingSpaceDoesNotTrigger() async {
    await assertNoViolation(TrailingWhitespaceRule.self, "//\n")
  }

  @Test func commentWithTrailingSpaceDoesNotTriggerByDefault() async {
    await assertNoViolation(TrailingWhitespaceRule.self, "// \n")
  }

  @Test func inlineCommentWithTrailingSpaceDoesNotTriggerByDefault() async {
    await assertNoViolation(TrailingWhitespaceRule.self, "let name: String // \n")
  }

  @Test func stringWithSpaceDoesNotTrigger() async {
    await assertNoViolation(TrailingWhitespaceRule.self, #"let stringWithSpace = "hello ""# + "\n")
  }

  // MARK: - Triggering (default)

  @Test func trailingSpaceTriggers() async {
    await assertViolates(TrailingWhitespaceRule.self, "let name: String \n")
  }

  @Test func blockCommentWithTrailingSpaceTriggers() async {
    await assertViolates(TrailingWhitespaceRule.self, "/* */ let name: String \n")
  }

  // MARK: - Corrections (default)

  @Test func correctsTrailingSpace() async {
    await assertFormatting(
      TrailingWhitespaceRule.self,
      input: "let name: String1️⃣ \n",
      expected: "let name: String\n",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func correctsBlockCommentTrailingSpace() async {
    await assertFormatting(
      TrailingWhitespaceRule.self,
      input: "/* */ let name: String1️⃣ \n",
      expected: "/* */ let name: String\n",
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - ignores_empty_lines = true

  @Test func emptyLineWithSpacesDoesNotTriggerWithIgnoresEmptyLines() async {
    await assertNoViolation(
      TrailingWhitespaceRule.self,
      " \n",
      configuration: ["ignores_empty_lines": true, "ignores_comments": true])
  }

  @Test func trailingSpaceStillTriggersWithIgnoresEmptyLines() async {
    await assertViolates(
      TrailingWhitespaceRule.self,
      "let name: String \n",
      configuration: ["ignores_empty_lines": true, "ignores_comments": true])
  }

  // MARK: - ignores_comments = false

  @Test func commentTrailingSpaceTriggersWithIgnoresCommentsDisabled() async {
    await assertViolates(
      TrailingWhitespaceRule.self,
      "// \n",
      configuration: ["ignores_empty_lines": false, "ignores_comments": false])
  }

  @Test func inlineCommentTrailingSpaceTriggersWithIgnoresCommentsDisabled() async {
    await assertViolates(
      TrailingWhitespaceRule.self,
      "let name: String // \n",
      configuration: ["ignores_empty_lines": false, "ignores_comments": false])
  }

  @Test func codeTrailingSpaceStillTriggersWithIgnoresCommentsDisabled() async {
    await assertViolates(
      TrailingWhitespaceRule.self,
      "let name: String \n",
      configuration: ["ignores_empty_lines": false, "ignores_comments": false])
  }

  // MARK: - ignores_literals = true

  @Test func multilineStringLiteralDoesNotTriggerWithIgnoresLiterals() async {
    await assertNoViolation(
      TrailingWhitespaceRule.self,
      "let multiline = \"\"\"\n    content   \n    \"\"\"\n",
      configuration: ["ignores_literals": true])
  }

  @Test func codeTrailingSpaceStillTriggersWithIgnoresLiterals() async {
    await assertViolates(
      TrailingWhitespaceRule.self,
      "let codeWithSpace = 123    \n",
      configuration: ["ignores_literals": true])
  }

  @Test func variableTrailingSpaceTriggersWithIgnoresLiterals() async {
    await assertViolates(
      TrailingWhitespaceRule.self,
      "var number = 42   \n",
      configuration: ["ignores_literals": true])
  }
}
