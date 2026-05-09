@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoFirstIndexOfInForLoopTests: RuleTesting {
  private static func message(_ method: String) -> String {
    "'.\(method)' on the iterated collection inside a 'for' loop is O(n²) — use '.enumerated()' for the index or precompute a '[Element: Index]' lookup outside the loop"
  }

  @Test func firstIndexOfOnIteratedFlagged() {
    assertLint(
      NoFirstIndexOfInForLoop.self,
      """
      for x in items {
        let i = items.1️⃣firstIndex(of: x)
        _ = i
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("firstIndex"))]
    )
  }

  @Test func firstIndexWhereOnIteratedFlagged() {
    assertLint(
      NoFirstIndexOfInForLoop.self,
      """
      for x in items {
        if let i = items.1️⃣firstIndex(where: { $0.id == x.id }) {
          print(i)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("firstIndex"))]
    )
  }

  @Test func firstIndexOnDifferentReceiverNotFlagged() {
    assertLint(
      NoFirstIndexOfInForLoop.self,
      """
      for x in items {
        let i = others.firstIndex(of: x)
        _ = i
      }
      """,
      findings: []
    )
  }

  @Test func firstIndexOutsideForLoopNotFlagged() {
    assertLint(
      NoFirstIndexOfInForLoop.self,
      """
      let i = items.firstIndex(of: target)
      """,
      findings: []
    )
  }

  @Test func firstIndexInNestedClosureNotFlagged() {
    assertLint(
      NoFirstIndexOfInForLoop.self,
      """
      for x in items {
        let mapped = others.map { items.firstIndex(of: $0) }
        _ = (x, mapped)
      }
      """,
      findings: []
    )
  }
}
