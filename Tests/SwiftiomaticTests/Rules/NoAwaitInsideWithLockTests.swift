@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoAwaitInsideWithLockTests: RuleTesting {
  @Test func awaitDirectlyInsideWithLock() {
    assertLint(
      NoAwaitInsideWithLock.self,
      """
      func run() async {
        await mutex.withLock {
          let value = 1️⃣await fetch()
          state = value
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'await' inside 'withLock' holds the lock across suspension — deadlock/blocking risk"),
      ]
    )
  }

  @Test func awaitNestedInIfInsideWithLock() {
    assertLint(
      NoAwaitInsideWithLock.self,
      """
      func run() async {
        mutex.withLock {
          if condition {
            _ = 1️⃣await fetch()
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'await' inside 'withLock' holds the lock across suspension — deadlock/blocking risk"),
      ]
    )
  }

  @Test func withLockNoAwaitNotFlagged() {
    assertLint(
      NoAwaitInsideWithLock.self,
      """
      func run() {
        mutex.withLock {
          state += 1
        }
      }
      """,
      findings: []
    )
  }

  @Test func awaitInsideNestedTaskIsAllowed() {
    assertLint(
      NoAwaitInsideWithLock.self,
      """
      func run() {
        mutex.withLock {
          Task {
            _ = await fetch()
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func nonWithLockUntouched() {
    assertLint(
      NoAwaitInsideWithLock.self,
      """
      func run() async {
        actor.run {
          _ = await fetch()
        }
      }
      """,
      findings: []
    )
  }

  @Test func explicitClosureArgument() {
    assertLint(
      NoAwaitInsideWithLock.self,
      """
      func run() async {
        mutex.withLock({
          let _ = 1️⃣await fetch()
        })
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'await' inside 'withLock' holds the lock across suspension — deadlock/blocking risk"),
      ]
    )
  }
}
