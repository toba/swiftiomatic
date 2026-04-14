@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLinesBetweenChainedFunctionsTests: RuleTesting {

  @Test func removesBlankLinesBetweenChainedFunctions() {
    assertFormatting(
      BlankLinesBetweenChainedFunctions.self,
      input: """
        [0, 1, 2]
            .map { $0 * 2 }



            1️⃣.map { $0 * 3 }
        """,
      expected: """
        [0, 1, 2]
            .map { $0 * 2 }
            .map { $0 * 3 }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank lines between chained function calls"),
      ]
    )
  }

  @Test func preservesCommentsRemovesBlankLines() {
    assertFormatting(
      BlankLinesBetweenChainedFunctions.self,
      input: """
        [0, 1, 2]
            .map { $0 * 2 }

            // Multiplies by 3

            1️⃣.map { $0 * 3 }
        """,
      expected: """
        [0, 1, 2]
            .map { $0 * 2 }
            // Multiplies by 3
            .map { $0 * 3 }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank lines between chained function calls"),
      ]
    )
  }

  @Test func noChangeWhenNoBlankLines() {
    assertFormatting(
      BlankLinesBetweenChainedFunctions.self,
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
      findings: []
    )
  }

  @Test func noChangeForNonChainedMemberAccess() {
    assertFormatting(
      BlankLinesBetweenChainedFunctions.self,
      input: """
        let x = foo

            .bar
        """,
      expected: """
        let x = foo

            .bar
        """,
      findings: []
    )
  }

  @Test func sameLineChainUnchanged() {
    assertFormatting(
      BlankLinesBetweenChainedFunctions.self,
      input: """
        [1, 2, 3].map { $0 * 2 }.filter { $0 > 3 }
        """,
      expected: """
        [1, 2, 3].map { $0 * 2 }.filter { $0 > 3 }
        """,
      findings: []
    )
  }
}
