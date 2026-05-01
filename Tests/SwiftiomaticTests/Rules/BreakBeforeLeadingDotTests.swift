@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct LeadingDelimitersTests: RuleTesting {

  // MARK: - Adapted from SwiftFormat

  @Test func leadingCommaMovedToPreviousLine() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        let foo = 5
            1️⃣, bar = 6
        """,
      expected: """
        let foo = 5,
            bar = 6
        """,
      findings: [
        FindingSpec("1️⃣", message: "move delimiter to end of previous line"),
      ]
    )
  }

  @Test func leadingColonFollowedByCommentMovedToPreviousLine() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        let foo
            1️⃣: /* string */ String
        """,
      expected: """
        let foo:
            /* string */ String
        """,
      findings: [
        FindingSpec("1️⃣", message: "move delimiter to end of previous line"),
      ]
    )
  }

  @Test func commaMovedBeforeCommentIfLineEndsInComment() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        let foo = 5 // first
            1️⃣, bar = 6
        """,
      expected: """
        let foo = 5, // first
            bar = 6
        """,
      findings: [
        FindingSpec("1️⃣", message: "move delimiter to end of previous line"),
      ]
    )
  }

  // MARK: - Additional tests

  @Test func noChangeWhenCommaAtEndOfLine() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        let foo = 5,
            bar = 6
        """,
      expected: """
        let foo = 5,
            bar = 6
        """,
      findings: []
    )
  }

  @Test func noChangeWhenColonNotLeading() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        let foo: String = "bar"
        """,
      expected: """
        let foo: String = "bar"
        """,
      findings: []
    )
  }

  @Test func leadingCommaInGuardCondition() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        guard let foo = maybeFoo
              1️⃣, let bar = maybeBar else { return }
        """,
      expected: """
        guard let foo = maybeFoo,
              let bar = maybeBar else { return }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move delimiter to end of previous line"),
      ]
    )
  }

  @Test func leadingCommaInFunctionParameters() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        func foo(a: Int
                 1️⃣, b: String) {}
        """,
      expected: """
        func foo(a: Int,
                 b: String) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "move delimiter to end of previous line"),
      ]
    )
  }

  @Test func singleLineNotAffected() {
    assertFormatting(
      BreakBeforeLeadingDot.self,
      input: """
        let (a, b, c) = (1, 2, 3)
        """,
      expected: """
        let (a, b, c) = (1, 2, 3)
        """,
      findings: []
    )
  }
}
