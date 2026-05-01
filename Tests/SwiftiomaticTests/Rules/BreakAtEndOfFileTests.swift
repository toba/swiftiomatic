@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BreakAtEndOfFileTests: RuleTesting {

  @Test func addsTrailingNewline() {
    assertFormatting(
      BreakAtEndOfFile.self,
      input: "let foo = 1\nlet bar = 21️⃣",
      expected: "let foo = 1\nlet bar = 2\n",
      findings: [
        FindingSpec("1️⃣", message: "add trailing newline at end of file"),
      ]
    )
  }

  @Test func noChangeWhenTrailingNewlineExists() {
    assertFormatting(
      BreakAtEndOfFile.self,
      input: "let foo = 1\nlet bar = 2\n",
      expected: "let foo = 1\nlet bar = 2\n",
      findings: []
    )
  }

  @Test func removesExtraTrailingNewlines() {
    assertFormatting(
      BreakAtEndOfFile.self,
      input: "let foo = 1\nlet bar = 2\n\n\n1️⃣",
      expected: "let foo = 1\nlet bar = 2\n",
      findings: [
        FindingSpec("1️⃣", message: "remove extra trailing newlines at end of file"),
      ]
    )
  }

  @Test func emptyFileGetsNewline() {
    assertFormatting(
      BreakAtEndOfFile.self,
      input: "1️⃣",
      expected: "\n",
      findings: [
        FindingSpec("1️⃣", message: "add trailing newline at end of file"),
      ]
    )
  }
}
