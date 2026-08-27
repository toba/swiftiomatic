import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseStructuredConcurrencyNotGCDTests: RuleTesting {
  private static let dispatchQueue =
    "'DispatchQueue' carries no isolation the compiler can check — use a task, a task group, or an actor"
  private static let dispatchGroup =
    "'DispatchGroup' waits without cancellation — use a task group, which awaits its children"
  private static let operationQueue =
    "'OperationQueue' predates structured concurrency — use a task group, or an actor for serialized state"

  @Test func dispatchQueueAsyncFlagged() {
    assertLint(
      UseStructuredConcurrencyNotGCD.self,
      """
      func refresh() {
        1️⃣DispatchQueue.main.async {
          update()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.dispatchQueue)]
    )
  }

  @Test func storedDispatchQueueFlagged() {
    assertLint(
      UseStructuredConcurrencyNotGCD.self,
      """
      final class Store {
        private let queue: 1️⃣DispatchQueue = .global()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.dispatchQueue)]
    )
  }

  @Test func dispatchGroupFlagged() {
    assertLint(
      UseStructuredConcurrencyNotGCD.self,
      """
      func waitForAll() {
        let group = 1️⃣DispatchGroup()
        group.wait()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.dispatchGroup)]
    )
  }

  @Test func operationQueueFlagged() {
    assertLint(
      UseStructuredConcurrencyNotGCD.self,
      """
      func schedule() {
        1️⃣OperationQueue.main.addOperation { update() }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.operationQueue)]
    )
  }

  @Test func structuredConcurrencyNotFlagged() {
    assertLint(
      UseStructuredConcurrencyNotGCD.self,
      """
      func refresh() async {
        await withTaskGroup(of: Void.self) { group in
          group.addTask { await update() }
        }
      }
      """,
      findings: []
    )
  }
}
