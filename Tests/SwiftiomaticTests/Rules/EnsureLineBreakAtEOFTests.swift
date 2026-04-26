@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct EnsureLineBreakAtEOFTests: RuleTesting {

  @Test func addsTrailingNewline() {
    assertFormatting(
      EnsureLineBreakAtEOF.self,
      input: "let foo = 1\nlet bar = 21️⃣",
      expected: "let foo = 1\nlet bar = 2\n",
      findings: [
        FindingSpec("1️⃣", message: "add trailing newline at end of file"),
      ]
    )
  }

  @Test func noChangeWhenTrailingNewlineExists() {
    assertFormatting(
      EnsureLineBreakAtEOF.self,
      input: "let foo = 1\nlet bar = 2\n",
      expected: "let foo = 1\nlet bar = 2\n",
      findings: []
    )
  }

  @Test func removesExtraTrailingNewlines() {
    assertFormatting(
      EnsureLineBreakAtEOF.self,
      input: "let foo = 1\nlet bar = 2\n\n\n1️⃣",
      expected: "let foo = 1\nlet bar = 2\n",
      findings: [
        FindingSpec("1️⃣", message: "remove extra trailing newlines at end of file"),
      ]
    )
  }

  @Test func emptyFileGetsNewline() {
    assertFormatting(
      EnsureLineBreakAtEOF.self,
      input: "1️⃣",
      expected: "\n",
      findings: [
        FindingSpec("1️⃣", message: "add trailing newline at end of file"),
      ]
    )
  }
}
