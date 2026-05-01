@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct InsertBlankLinesAroundMarkTests: RuleTesting {

  @Test func insertInsertBlankLinesAroundMark() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        let foo = "foo"
        1️⃣// MARK: bar
        2️⃣let bar = "bar"
        """,
      expected: """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before MARK comment"),
        FindingSpec("2️⃣", message: "insert blank line after MARK comment"),
      ]
    )
  }

  @Test func noInsertExtraInsertBlankLinesAroundMark() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """,
      expected: """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """,
      findings: []
    )
  }

  @Test func insertBlankLineAfterMarkAtStartOfFile() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        // MARK: bar
        1️⃣let bar = "bar"
        """,
      expected: """
        // MARK: bar

        let bar = "bar"
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after MARK comment"),
      ]
    )
  }

  @Test func insertBlankLineBeforeMarkAtEndOfFile() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        let foo = "foo"
        1️⃣// MARK: bar
        """,
      expected: """
        let foo = "foo"

        // MARK: bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before MARK comment"),
      ]
    )
  }

  @Test func noInsertBlankLineAfterMarkAtEndOfScope() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        do {
            let foo = "foo"

            // MARK: foo
        }
        """,
      expected: """
        do {
            let foo = "foo"

            // MARK: foo
        }
        """,
      findings: []
    )
  }

  @Test func noInsertBlankLineBeforeMarkAtStartOfScope() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        do {
            // MARK: foo

            let foo = "foo"
        }
        """,
      expected: """
        do {
            // MARK: foo

            let foo = "foo"
        }
        """,
      findings: []
    )
  }

  @Test func insertOnlyBeforeMark() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        let foo = "foo"
        1️⃣// MARK: bar

        let bar = "bar"
        """,
      expected: """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before MARK comment"),
      ]
    )
  }

  @Test func insertOnlyAfterMark() {
    assertFormatting(
      InsertBlankLinesAroundMark.self,
      input: """
        let foo = "foo"

        // MARK: bar
        1️⃣let bar = "bar"
        """,
      expected: """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after MARK comment"),
      ]
    )
  }
}
