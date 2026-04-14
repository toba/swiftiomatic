@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct TodosTests: RuleTesting {

  // MARK: - MARK formatting

  @Test func markIsUpdated() {
    assertFormatting(
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
      Todos.self,
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
