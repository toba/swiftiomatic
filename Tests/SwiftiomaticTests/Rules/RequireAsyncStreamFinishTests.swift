@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireAsyncStreamFinishTests: RuleTesting {
  @Test func yieldWithoutFinishOrTerminationFlagged() {
    assertLint(
      RequireAsyncStreamFinish.self,
      """
      let stream = 1️⃣AsyncStream { continuation in
        for value in source {
          continuation.yield(value)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'AsyncStream' yields without 'finish()' or 'onTermination' — consumer cancellation will leak the producer"),
      ]
    )
  }

  @Test func yieldWithFinishNotFlagged() {
    assertLint(
      RequireAsyncStreamFinish.self,
      """
      let stream = AsyncStream { continuation in
        for value in source {
          continuation.yield(value)
        }
        continuation.finish()
      }
      """,
      findings: []
    )
  }

  @Test func yieldWithOnTerminationNotFlagged() {
    assertLint(
      RequireAsyncStreamFinish.self,
      """
      let stream = AsyncStream { continuation in
        continuation.onTermination = { _ in
          source.cancel()
        }
        for value in source {
          continuation.yield(value)
        }
      }
      """,
      findings: []
    )
  }

  @Test func asyncThrowingStreamFlagged() {
    assertLint(
      RequireAsyncStreamFinish.self,
      """
      let stream = 1️⃣AsyncThrowingStream { continuation in
        continuation.yield(1)
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'AsyncStream' yields without 'finish()' or 'onTermination' — consumer cancellation will leak the producer"),
      ]
    )
  }

  @Test func noYieldNotFlagged() {
    assertLint(
      RequireAsyncStreamFinish.self,
      """
      let stream = AsyncStream { continuation in
        // empty producer
      }
      """,
      findings: []
    )
  }

  @Test func nonAsyncStreamCallNotFlagged() {
    assertLint(
      RequireAsyncStreamFinish.self,
      """
      let s = MyStream { c in
        c.yield(1)
      }
      """,
      findings: []
    )
  }
}
