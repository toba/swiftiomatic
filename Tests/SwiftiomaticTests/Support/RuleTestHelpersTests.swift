import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

/// Validates that the assertLint/assertFormatting test infrastructure works correctly.
@Suite(.rulesRegistered)
struct RuleTestHelpersTests {
  // MARK: - MarkedText

  @Test func markedTextExtractsMarkers() {
    let marked = MarkedText("let x = 1️⃣foo!")
    #expect(marked.markers == ["1️⃣": 8])
    #expect(marked.textWithoutMarkers == "let x = foo!")
  }

  @Test func markedTextMultipleMarkers() {
    let marked = MarkedText("1️⃣let x = 2️⃣foo")
    #expect(marked.markers.count == 2)
    #expect(marked.markers["1️⃣"] == 0)
    #expect(marked.markers["2️⃣"] == 8)
    #expect(marked.textWithoutMarkers == "let x = foo")
  }

  @Test func markedTextNoMarkers() {
    let marked = MarkedText("let x = 1")
    #expect(marked.markers.isEmpty)
    #expect(marked.textWithoutMarkers == "let x = 1")
  }

  // MARK: - assertLint

  @Test func assertLintDetectsViolation() async {
    // Trailing whitespace rule should fire on trailing spaces
    await assertLint(
      TrailingWhitespaceRule.self, "let name: String1️⃣ \n",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func assertLintNoViolation() async {
    await assertNoViolation(TrailingWhitespaceRule.self, "let name: String\n")
  }

  // MARK: - assertFormatting

  @Test func assertFormattingCorrects() async {
    await assertFormatting(
      TrailingWhitespaceRule.self,
      input: "let name: String1️⃣ \n",
      expected: "let name: String\n",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func assertFormattingNoChange() async {
    await assertFormatting(
      TrailingWhitespaceRule.self,
      input: "let name: String\n",
      expected: "let name: String\n"
    )
  }
}
