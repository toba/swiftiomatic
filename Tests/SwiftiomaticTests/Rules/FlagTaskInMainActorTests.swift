@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagTaskInMainActorTests: RuleTesting {
  private static let message =
    "'Task { ... }' from a '@MainActor' context hops off the main actor unless the body's first work is main-actor-isolated — use 'Task.immediate' to start synchronously on the calling actor"

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
}
