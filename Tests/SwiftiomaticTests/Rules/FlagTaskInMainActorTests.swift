@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagTaskInMainActorTests: RuleTesting {
  private static let message =
    "'Task { ... }' on the main actor inherits the caller's isolation but defers its start to a later turn; use 'Task.immediate' to start synchronously on the calling actor"

  @Test func taskInMainActorFunctionFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      @MainActor
      func reload() {
        1️⃣Task {
          await refresh()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func taskInMainActorTypeFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      @MainActor
      final class Coordinator {
        func start() {
          1️⃣Task {
            await load()
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func taskWithPriorityInMainActorFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      @MainActor
      func reload() {
        1️⃣Task(priority: .userInitiated) {
          await refresh()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func taskOutsideMainActorNotFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      func reload() {
        Task {
          await refresh()
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskDetachedNotFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      @MainActor
      func reload() {
        Task.detached {
          await refresh()
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskImmediateNotFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      @MainActor
      func reload() {
        Task.immediate {
          await refresh()
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskStatementInIBActionFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      final class ViewController: NSViewController {
        @IBAction func reload(_ sender: Any) {
          1️⃣Task {
            await refresh()
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func taskAssignedInIBActionNotFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      final class ViewController: NSViewController {
        var loading: Task<Void, Never>?

        @IBAction func reload(_ sender: Any) {
          loading = Task {
            await refresh()
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskInNonIBActionFunctionNotFlagged() {
    assertLint(
      FlagTaskInMainActor.self,
      """
      final class ViewController: NSViewController {
        func reload(_ sender: Any) {
          Task {
            await refresh()
          }
        }
      }
      """,
      findings: []
    )
  }
}
