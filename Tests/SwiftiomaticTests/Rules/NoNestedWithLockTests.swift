@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoNestedWithLockTests: RuleTesting {
  @Test func nestedSameReceiver() {
    assertLint(
      NoNestedWithLock.self,
      """
      func run() {
        mutex.withLock {
          state += 1
          1️⃣mutex.withLock {
            state += 1
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "nested 'withLock' on the same receiver — re-entering a non-recursive lock deadlocks"),
      ]
    )
  }

  @Test func nestedSelfMutex() {
    assertLint(
      NoNestedWithLock.self,
      """
      func run() {
        self.mutex.withLock {
          1️⃣self.mutex.withLock {
            state += 1
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "nested 'withLock' on the same receiver — re-entering a non-recursive lock deadlocks"),
      ]
    )
  }

  @Test func nestedDifferentReceiverNotFlagged() {
    assertLint(
      NoNestedWithLock.self,
      """
      func run() {
        a.withLock {
          b.withLock {
            state += 1
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func singleWithLockNotFlagged() {
    assertLint(
      NoNestedWithLock.self,
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

  @Test func adjacentWithLocksNotFlagged() {
    assertLint(
      NoNestedWithLock.self,
      """
      func run() {
        mutex.withLock { state = 1 }
        mutex.withLock { state = 2 }
      }
      """,
      findings: []
    )
  }
}
