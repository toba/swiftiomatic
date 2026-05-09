@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagTaskDetachedTests: RuleTesting {
  private static let message =
    "'Task.detached' breaks structured concurrency and drops '@TaskLocal' inheritance — use a '@concurrent' function or 'Task.immediateDetached' instead"

  @Test func taskDetachedFlagged() {
    assertLint(
      FlagTaskDetached.self,
      """
      func go() {
        Task.1️⃣detached {
          await work()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func taskDetachedWithPriorityFlagged() {
    assertLint(
      FlagTaskDetached.self,
      """
      func go() {
        Task.1️⃣detached(priority: .background) {
          await work()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func plainTaskNotFlagged() {
    assertLint(
      FlagTaskDetached.self,
      """
      func go() {
        Task {
          await work()
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskImmediateDetachedNotFlagged() {
    assertLint(
      FlagTaskDetached.self,
      """
      func go() {
        Task.immediateDetached {
          await work()
        }
      }
      """,
      findings: []
    )
  }

  @Test func unrelatedDetachedNotFlagged() {
    assertLint(
      FlagTaskDetached.self,
      """
      func go() {
        scene.detached(for: window)
      }
      """,
      findings: []
    )
  }
}
