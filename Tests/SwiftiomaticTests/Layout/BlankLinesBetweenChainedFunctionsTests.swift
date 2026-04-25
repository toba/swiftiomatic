@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLinesBetweenChainedFunctionsTests: LayoutTesting {

  @Test func removesBlankLinesBetweenChainedCalls() {
    assertLayout(
      input: """
        [0, 1, 2]
          .map { $0 * 2 }


          .map { $0 * 3 }
        """,
      expected: """
        [0, 1, 2]
          .map { $0 * 2 }
          .map { $0 * 3 }

        """,
      linelength: 100
    )
  }

  @Test func noChangeWhenNoBlankLines() {
    assertLayout(
      input: """
        [0, 1, 2]
          .map { $0 * 2 }
          .filter { $0 > 3 }
          .reduce(0, +)
        """,
      expected: """
        [0, 1, 2]
          .map { $0 * 2 }
          .filter { $0 > 3 }
          .reduce(0, +)

        """,
      linelength: 100
    )
  }

  @Test func sameLineChainUnchanged() {
    assertLayout(
      input: """
        [1, 2, 3].map { $0 * 2 }.filter { $0 > 3 }
        """,
      expected: """
        [1, 2, 3].map { $0 * 2 }.filter { $0 > 3 }

        """,
      linelength: 100
    )
  }
}
