@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct TodosTests: RuleTesting {

  // MARK: - MARK formatting

  @Test func markIsUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// MARK foo
        let x = 1
        """,
      expected: """
        // MARK: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - TODO formatting

  @Test func todoIsUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// TODO foo
        let x = 1
        """,
      expected: """
        // TODO: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - FIXME formatting

  @Test func fixmeIsUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣//    FIXME foo
        let x = 1
        """,
      expected: """
        //    FIXME: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - Colon spacing

  @Test func markWithColonSeparatedBySpace() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// MARK : foo
        let x = 1
        """,
      expected: """
        // MARK: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - Triple-slash conversion

  @Test func markWithTripleSlash() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣/// MARK: foo
        let x = 1
        """,
      expected: """
        // MARK: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - In-place replacement

  @Test func todoReplacedInMiddleOfCommentBlock() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        // Some comment
        1️⃣// todo : foo
        // Some more comment
        let x = 1
        """,
      expected: """
        // Some comment
        // TODO: foo
        // Some more comment
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - Doc block exclusion

  @Test func todoNotReplacedInMiddleOfDocBlock() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        /// Some docs
        /// TODO: foo
        /// Some more docs
        let x = 1
        """,
      expected: """
        /// Some docs
        /// TODO: foo
        /// Some more docs
        let x = 1
        """,
      findings: []
    )
  }

  @Test func todoNotReplacedAtStartOfDocBlock() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        /// TODO: foo
        /// Some docs
        let x = 1
        """,
      expected: """
        /// TODO: foo
        /// Some docs
        let x = 1
        """,
      findings: []
    )
  }

  @Test func todoNotReplacedAtEndOfDocBlock() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        /// Some docs
        /// TODO: foo
        let x = 1
        """,
      expected: """
        /// Some docs
        /// TODO: foo
        let x = 1
        """,
      findings: []
    )
  }

  // MARK: - No space after colon

  @Test func markWithNoSpaceAfterColon() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// MARK:foo
        let x = 1
        """,
      expected: """
        // MARK: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - Block comments

  @Test func markInsideMultilineComment() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣/* MARK foo */
        let x = 1
        """,
      expected: """
        /* MARK: foo */
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  @Test func noExtraSpaceAddedAfterTodo() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        /* TODO: */
        let x = 1
        """,
      expected: """
        /* TODO: */
        let x = 1
        """,
      findings: []
    )
  }

  // MARK: - Case normalization

  @Test func lowercaseMarkColonIsUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// mark: foo
        let x = 1
        """,
      expected: """
        // MARK: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  @Test func mixedCaseMarkColonIsUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// Mark: foo
        let x = 1
        """,
      expected: """
        // MARK: foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  // MARK: - Non-tag comments

  @Test func lowercaseMarkIsNotUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        // mark as read
        let x = 1
        """,
      expected: """
        // mark as read
        let x = 1
        """,
      findings: []
    )
  }

  @Test func mixedCaseMarkIsNotUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        // Mark as read
        let x = 1
        """,
      expected: """
        // Mark as read
        let x = 1
        """,
      findings: []
    )
  }

  // MARK: - MARK dash formatting

  @Test func lowercaseMarkDashIsUpdated() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// mark - foo
        let x = 1
        """,
      expected: """
        // MARK: - foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  @Test func spaceAddedBeforeMarkDash() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// MARK:- foo
        let x = 1
        """,
      expected: """
        // MARK: - foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  @Test func spaceAddedAfterMarkDash() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// MARK: -foo
        let x = 1
        """,
      expected: """
        // MARK: - foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  @Test func spaceAddedAroundMarkDash() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        1️⃣// MARK:-foo
        let x = 1
        """,
      expected: """
        // MARK: - foo
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "use correct formatting for TODO/MARK/FIXME comment"),
      ]
    )
  }

  @Test func spaceNotAddedAfterMarkDashAtEndOfString() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        // MARK: -
        let x = 1
        """,
      expected: """
        // MARK: -
        let x = 1
        """,
      findings: []
    )
  }

  // MARK: - Already correct

  @Test func correctTodoUnchanged() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        // TODO: fix this
        let x = 1
        """,
      expected: """
        // TODO: fix this
        let x = 1
        """,
      findings: []
    )
  }

  @Test func correctMarkUnchanged() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        // MARK: - Properties
        let x = 1
        """,
      expected: """
        // MARK: - Properties
        let x = 1
        """,
      findings: []
    )
  }

  @Test func correctFixmeUnchanged() {
    assertFormatting(
      FormatSpecialComments.self,
      input: """
        // FIXME: broken
        let x = 1
        """,
      expected: """
        // FIXME: broken
        let x = 1
        """,
      findings: []
    )
  }
}
