@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseContinuationNotCheckedTests: RuleTesting {
  private static let message =
    "a checked continuation traps on a double resume and leaks the awaiting task on a missed one — use 'withContinuation' (SE-0528), whose noncopyable 'Continuation' makes the double resume a compile error"

  @Test func checkedContinuationFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await 1️⃣withCheckedContinuation { continuation in
          fetch { continuation.resume(returning: $0) }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func unsafeContinuationFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await 1️⃣withUnsafeContinuation { continuation in
          fetch { continuation.resume(returning: $0) }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func throwingFormsFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async throws -> Data {
        let a = try await 1️⃣withCheckedThrowingContinuation { c in fetch(c) }
        let b = try await 2️⃣withUnsafeThrowingContinuation { c in fetch(c) }
        return a + b
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
      ]
    )
  }

  @Test func withContinuationNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await withContinuation { continuation in
          fetch { continuation.resume(returning: $0) }
        }
      }
      """,
      findings: []
    )
  }

  @Test func memberCallNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await helper.withCheckedContinuation { c in fetch(c) }
      }
      """,
      findings: []
    )
  }
}
