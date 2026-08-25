@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseContinuationNotCheckedTests: RuleTesting {
  private static let message =
    "a checked continuation traps on a double resume and leaks the awaiting task on a missed one — use 'withContinuation' (SE-0528), whose noncopyable 'Continuation' makes the double resume a compile error"
  private static let throwingMessage =
    "a checked continuation traps on a double resume and leaks the awaiting task on a missed one — use 'withContinuation(throwing: (any Error).self)' (SE-0528), whose noncopyable 'Continuation' makes the double resume a compile error"

  @Test func checkedContinuationFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await 1️⃣withCheckedContinuation { continuation in
          continuation.resume(returning: cached)
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
          if let cached {
            continuation.resume(returning: cached)
          } else {
            continuation.resume(returning: .empty)
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func shorthandParameterFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await 1️⃣withCheckedContinuation {
          $0.resume(returning: cached)
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
        let a = try await 1️⃣withCheckedThrowingContinuation { c in c.resume(returning: first) }
        let b = try await 2️⃣withUnsafeThrowingContinuation { c in c.resume(returning: second) }
        return a + b
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.throwingMessage),
        FindingSpec("2️⃣", message: Self.throwingMessage),
      ]
    )
  }

  @Test func escapingCallbackNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await withCheckedContinuation { continuation in
          fetch { continuation.resume(returning: $0) }
        }
      }
      """,
      findings: []
    )
  }

  @Test func operationCallbackNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func metadata() async throws -> ShareMetadata {
        try await withUnsafeThrowingContinuation { continuation in
          let operation = CKFetchShareMetadataOperation(shareURLs: urls)
          operation.perShareMetadataResultBlock = { _, result in
            continuation.resume(with: result)
          }
          add(operation)
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskCaptureNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await withCheckedContinuation { continuation in
          Task.immediate {
            let value = await fetch()
            continuation.resume(returning: value)
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func storedContinuationNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await withCheckedContinuation { continuation in
          box.value = continuation
        }
      }
      """,
      findings: []
    )
  }

  @Test func continuationPassedAsArgumentNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await withCheckedContinuation { continuation in
          register(continuation)
        }
      }
      """,
      findings: []
    )
  }

  @Test func withContinuationNotFlagged() {
    assertLint(
      UseContinuationNotChecked.self,
      """
      func load() async -> Data {
        await withContinuation { continuation in
          continuation.resume(returning: cached)
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
        await helper.withCheckedContinuation { c in c.resume(returning: cached) }
      }
      """,
      findings: []
    )
  }
}
