import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseActorNotLockTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'\(name)' guards state the compiler cannot see — use an actor, or 'Mutex' from Synchronization when the critical section is synchronous"
  }

  @Test func storedNSLockFlagged() {
    assertLint(
      UseActorNotLock.self,
      """
      final class Store {
        private let lock = 1️⃣NSLock()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("NSLock"))]
    )
  }

  @Test func annotatedLockTypeFlagged() {
    assertLint(
      UseActorNotLock.self,
      """
      final class Store {
        private var lock: 1️⃣os_unfair_lock = .init()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("os_unfair_lock"))]
    )
  }

  @Test func pthreadMutexFlagged() {
    assertLint(
      UseActorNotLock.self,
      """
      final class Store {
        private var mutex: 1️⃣pthread_mutex_t = .init()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("pthread_mutex_t"))]
    )
  }

  @Test func mutexNotFlagged() {
    assertLint(
      UseActorNotLock.self,
      """
      final class Store {
        private let state = Mutex(0)
      }
      """,
      findings: []
    )
  }

  @Test func actorNotFlagged() {
    assertLint(
      UseActorNotLock.self,
      """
      actor Store {
        private var count = 0
      }
      """,
      findings: []
    )
  }
}
