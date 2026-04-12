import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct LinebreaksRuleTests {
  // MARK: - Non-triggering (LF only)

  @Test func lfLineEndingsDoNotTrigger() async {
    await assertNoViolation(LinebreaksRule.self, "let a = 0\nlet b = 1\n")
  }

  @Test func singleLineDoesNotTrigger() async {
    await assertNoViolation(LinebreaksRule.self, "let a = 0")
  }

  @Test func emptyFileDoesNotTrigger() async {
    await assertNoViolation(LinebreaksRule.self, "")
  }

  // MARK: - Triggering (CRLF)

  @Test func crlfLineEndingsTrigger() async {
    await assertViolates(LinebreaksRule.self, "let a = 0\r\nlet b = 1\r\n")
  }

  @Test func mixedLfCrlfTriggers() async {
    await assertViolates(LinebreaksRule.self, "let a = 0\nlet b = 1\r\n")
  }

  @Test func crOnlyTriggers() async {
    await assertViolates(LinebreaksRule.self, "let a = 0\rlet b = 1\r")
  }

  // MARK: - Corrections (CRLF → LF)

  @Test func correctsCrlfToLf() async {
    await assertFormatting(
      LinebreaksRule.self,
      input: "let a = 0\r\nlet b = 1\r\n",
      expected: "let a = 0\nlet b = 1\n")
  }

  @Test func correctsCrToLf() async {
    await assertFormatting(
      LinebreaksRule.self,
      input: "let a = 0\rlet b = 1\r",
      expected: "let a = 0\nlet b = 1\n")
  }

  @Test func correctsMixedLineEndingsToLf() async {
    await assertFormatting(
      LinebreaksRule.self,
      input: "let a = 0\r\nlet b = 1\nlet c = 2\r\n",
      expected: "let a = 0\nlet b = 1\nlet c = 2\n")
  }
}
