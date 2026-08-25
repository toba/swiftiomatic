@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseSpanTemporaryAllocationTests: RuleTesting {
  private static let message =
    "'withUnsafeTemporaryAllocation' hands you an uninitialised buffer — use 'withTemporaryAllocation' (SE-0524), which yields an 'OutputSpan' that deinitialises on every exit path"

  @Test func typedAllocationFlagged() {
    assertLint(
      UseSpanTemporaryAllocation.self,
      """
      func sum(_ n: Int) -> Int {
        1️⃣withUnsafeTemporaryAllocation(of: Float.self, capacity: n) { buffer in
          aggregate(buffer)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func rawAllocationFlagged() {
    assertLint(
      UseSpanTemporaryAllocation.self,
      """
      func pack() {
        1️⃣withUnsafeTemporaryAllocation(byteCount: 16, alignment: 4) { bytes in
          fill(bytes)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func spanFormNotFlagged() {
    assertLint(
      UseSpanTemporaryAllocation.self,
      """
      func sum(_ n: Int) -> Int {
        withTemporaryAllocation(of: Float.self, capacity: n) { output in
          aggregate(output.span)
        }
      }
      """,
      findings: []
    )
  }

  @Test func otherUnsafeCallNotFlagged() {
    assertLint(
      UseSpanTemporaryAllocation.self,
      """
      func read(_ data: Data) {
        data.withUnsafeBytes { bytes in parse(bytes) }
      }
      """,
      findings: []
    )
  }
}
