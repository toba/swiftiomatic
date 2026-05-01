@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoSwapThenRemoveAllTests: RuleTesting {
  @Test func swapThenRemoveAllOnFirstFlagged() {
    assertLint(
      NoSwapThenRemoveAll.self,
      """
      func tick() {
        swap(&current, &next)
        1️⃣current.removeAll(keepingCapacity: true)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'swap(&current, &next)' followed by 'current.removeAll' is the alternating-buffer pattern — fragile; consider an explicit double-buffer or 'reserveCapacity' on a single buffer"),
      ]
    )
  }

  @Test func swapThenRemoveAllOnSecondFlagged() {
    assertLint(
      NoSwapThenRemoveAll.self,
      """
      func tick() {
        swap(&a, &b)
        1️⃣b.removeAll()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'swap(&a, &b)' followed by 'b.removeAll' is the alternating-buffer pattern — fragile; consider an explicit double-buffer or 'reserveCapacity' on a single buffer"),
      ]
    )
  }

  @Test func swapWithoutRemoveAllNotFlagged() {
    assertLint(
      NoSwapThenRemoveAll.self,
      """
      func tick() {
        swap(&a, &b)
        process(a)
      }
      """,
      findings: []
    )
  }

  @Test func removeAllOnDifferentReceiverNotFlagged() {
    assertLint(
      NoSwapThenRemoveAll.self,
      """
      func tick() {
        swap(&a, &b)
        c.removeAll()
      }
      """,
      findings: []
    )
  }

  @Test func nonSwapThenRemoveAllNotFlagged() {
    assertLint(
      NoSwapThenRemoveAll.self,
      """
      func tick() {
        process(a)
        a.removeAll()
      }
      """,
      findings: []
    )
  }
}
