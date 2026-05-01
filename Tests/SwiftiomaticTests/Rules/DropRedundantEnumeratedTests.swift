@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantEnumeratedTests: RuleTesting {
  @Test func indexUnusedDropsEnumerated() {
    assertFormatting(
      DropRedundantEnumerated.self,
      input: """
        for (1️⃣_, item) in items.enumerated() {
          print(item)
        }
        """,
      expected: """
        for item in items {
          print(item)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "drop '.enumerated()'; the index is unused"),
      ]
    )
  }

  @Test func itemUnusedSwitchesToIndices() {
    assertFormatting(
      DropRedundantEnumerated.self,
      input: """
        for (i, 1️⃣_) in items.enumerated() {
          print(i)
        }
        """,
      expected: """
        for i in items.indices {
          print(i)
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "use '.indices' instead of '.enumerated()'; the element is unused"
        ),
      ]
    )
  }

  @Test func bothUsedNotFlagged() {
    assertFormatting(
      DropRedundantEnumerated.self,
      input: """
        for (i, item) in items.enumerated() {
          print(i, item)
        }
        """,
      expected: """
        for (i, item) in items.enumerated() {
          print(i, item)
        }
        """,
      findings: []
    )
  }

  @Test func bothUnusedNotFlagged() {
    assertFormatting(
      DropRedundantEnumerated.self,
      input: """
        for (_, _) in items.enumerated() {
          print("loop")
        }
        """,
      expected: """
        for (_, _) in items.enumerated() {
          print("loop")
        }
        """,
      findings: []
    )
  }

  @Test func chainedAfterEnumeratedNotFlagged() {
    assertFormatting(
      DropRedundantEnumerated.self,
      input: """
        for (_, x) in items.enumerated().filter({ $0 > 0 }) {
          print(x)
        }
        """,
      expected: """
        for (_, x) in items.enumerated().filter({ $0 > 0 }) {
          print(x)
        }
        """,
      findings: []
    )
  }

  @Test func nonEnumeratedCallNotFlagged() {
    assertFormatting(
      DropRedundantEnumerated.self,
      input: """
        for (_, x) in items.indexed() {
          print(x)
        }
        """,
      expected: """
        for (_, x) in items.indexed() {
          print(x)
        }
        """,
      findings: []
    )
  }
}
