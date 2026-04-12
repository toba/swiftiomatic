import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct FileLengthRuleTests {
  // MARK: - Helpers

  /// Generate a source string with the given number of code lines.
  private static func codeLines(_ count: Int) -> String {
    String(repeating: "print(\"swiftlint\")\n", count: count)
  }

  /// Generate a source string with alternating code and blank lines (2 lines per iteration).
  private static func codeLinesWithBlanks(_ count: Int) -> String {
    String(repeating: "print(\"swiftlint\")\n\n", count: count)
  }

  // MARK: - Non-triggering (default config: warning at 400)

  @Test func fileUnderLimitDoesNotTrigger() async {
    // 399 lines is under the 400 warning threshold
    await assertNoViolation(FileLengthRule.self, Self.codeLines(399))
  }

  @Test func fileAtLimitDoesNotTrigger() async {
    // 400 lines is exactly at the threshold, not over
    await assertNoViolation(FileLengthRule.self, Self.codeLines(400))
  }

  // MARK: - Triggering (default config: warning at 400)

  @Test func fileOverLimitTriggers() async {
    // 401 lines exceeds the 400 warning threshold
    await assertViolates(FileLengthRule.self, Self.codeLines(401))
  }

  @Test func codeWithTrailingCommentOverLimitTriggers() async {
    // 400 code lines + 1 comment line = 401 total
    let source = Self.codeLines(400) + "//\n"
    await assertViolates(FileLengthRule.self, source)
  }

  @Test func blankLinesCountTowardLimit() async {
    // 201 iterations * 2 lines each = 402 total lines
    await assertViolates(FileLengthRule.self, Self.codeLinesWithBlanks(201))
  }

  // MARK: - Configuration: ignore_comment_only_lines

  @Test func commentOnlyLinesIgnoredWhenConfigured() async {
    // 400 code lines + 1 comment = 401 total, but only 400 non-comment lines
    let source = Self.codeLines(400) + "//\n"
    await assertNoViolation(
      FileLengthRule.self,
      source,
      configuration: ["ignore_comment_only_lines": true])
  }

  @Test func codeOnlyFileStillTriggersWithIgnoreComments() async {
    // 401 code lines still exceeds threshold even when ignoring comments
    await assertViolates(
      FileLengthRule.self,
      Self.codeLines(401),
      configuration: ["ignore_comment_only_lines": true])
  }

  @Test func blankLinesIgnoredWithCommentConfig() async {
    // 400 code lines + blank lines; blank lines don't count as "code" lines
    await assertNoViolation(
      FileLengthRule.self,
      Self.codeLinesWithBlanks(201),
      configuration: ["ignore_comment_only_lines": true])
  }

  @Test func fileUnderLimitWithIgnoreComments() async {
    await assertNoViolation(
      FileLengthRule.self,
      Self.codeLines(400),
      configuration: ["ignore_comment_only_lines": true])
  }
}
