@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoEmptyLinesOpeningClosingBracesTests: LayoutTesting {

  @Test func removesBlankLinesInCodeBlock() {
    assertLayout(
      input: """
        func f() {

          return 1

        }
        """,
      expected: """
        func f() {
          return 1
        }

        """,
      linelength: 100
    )
  }

  @Test func removesBlankLinesInMemberBlock() {
    assertLayout(
      input: """
        struct S {

          let x: Int

          let y: Int

        }
        """,
      expected: """
        struct S {
          let x: Int

          let y: Int
        }

        """,
      linelength: 100
    )
  }

  @Test func removesBlankLinesInClosureExpr() {
    assertLayout(
      input: """
        let closure = {

          return 1

        }
        """,
      expected: """
        let closure = {
          return 1
        }

        """,
      linelength: 100
    )
  }

  @Test func preservesInternalBlankLines() {
    assertLayout(
      input: """
        func myFunc() {
          let x = 1

          let y = 2
        }
        """,
      expected: """
        func myFunc() {
          let x = 1

          let y = 2
        }

        """,
      linelength: 100
    )
  }

  @Test func noChangeWhenAlreadyCorrect() {
    assertLayout(
      input: """
        func f() {
          return 1
        }
        """,
      expected: """
        func f() {
          return 1
        }

        """,
      linelength: 100
    )
  }
}
