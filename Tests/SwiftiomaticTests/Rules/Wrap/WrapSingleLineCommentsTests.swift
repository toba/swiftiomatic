@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapSingleLineCommentsTests: RuleTesting {

  private func config(maxWidth: Int) -> Configuration {
    var c = Configuration.forTesting(enabledRule: WrapSingleLineComments.self.key)
    c[LineLength.self] = maxWidth
    return c
  }

  // MARK: - Basic wrapping

  @Test func wrapSingleLineComment() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        1️⃣// a b cde fgh
        """,
      expected: """
        // a b
        // cde
        // fgh
        """,
      findings: [FindingSpec("1️⃣", message: "wrap comment to fit within line length")],
      configuration: config(maxWidth: 6))
  }

  @Test func wrapSingleLineCommentThatOverflowsByOneCharacter() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        1️⃣// a b cde fg h
        """,
      expected: """
        // a b cde fg
        // h
        """,
      findings: [FindingSpec("1️⃣", message: "wrap comment to fit within line length")],
      configuration: config(maxWidth: 14))
  }

  @Test func noWrapSingleLineCommentThatExactlyFits() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        // a b cde fg h
        """,
      expected: """
        // a b cde fg h
        """,
      configuration: config(maxWidth: 15))
  }

  // MARK: - Doc comments

  @Test func wrapDocComment() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        1️⃣/// a b cde fgh
        """,
      expected: """
        /// a b
        /// cde
        /// fgh
        """,
      findings: [FindingSpec("1️⃣", message: "wrap comment to fit within line length")],
      configuration: config(maxWidth: 7))
  }

  // MARK: - Indented comments

  @Test func wrapSingleLineCommentWithIndent() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        func f() {
            1️⃣// a b cde fgh
            let x = 1
        }
        """,
      expected: """
        func f() {
            // a b cde
            // fgh
            let x = 1
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap comment to fit within line length")],
      configuration: config(maxWidth: 14))
  }

  // MARK: - Directives should not wrap

  @Test func commentDirectiveNotWrapped() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        // MARK: - This is a very very very long mark comment that should not be wrapped
        """,
      expected: """
        // MARK: - This is a very very very long mark comment that should not be wrapped
        """,
      configuration: config(maxWidth: 40))
  }

  @Test func swiftiomaticIgnoreNotWrapped() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        // sm:ignore: SomeRule - this is very long
        """,
      expected: """
        // sm:ignore: SomeRule - this is very long
        """,
      configuration: config(maxWidth: 20))
  }

  // MARK: - Long URLs should not wrap

  @Test func commentWithLongURLNotWrapped() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        /// See https://www.domain.com/pathextension/pathextension/pathextension/pathextension
        """,
      expected: """
        /// See https://www.domain.com/pathextension/pathextension/pathextension/pathextension
        """,
      configuration: config(maxWidth: 40))
  }

  // MARK: - No-ops

  @Test func shortCommentUnchanged() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        // short
        """,
      expected: """
        // short
        """,
      configuration: config(maxWidth: 80))
  }

  @Test func codeWithNoCommentUnchanged() {
    assertFormatting(
      WrapSingleLineComments.self,
      input: """
        let x = 1
        """,
      expected: """
        let x = 1
        """,
      configuration: config(maxWidth: 10))
  }
}
