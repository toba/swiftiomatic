@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseOptionalTakeTests: RuleTesting {
  private static func message(_ storage: String) -> String {
    "read '\(storage)' and clear it in one step with '\(storage).take()'"
  }

  @Test func ifLetThenClear() {
    assertLint(
      UseOptionalTake.self,
      """
      func configure() {
        if 1️⃣let accepted = pendingShare {
          pendingShare = nil
          Task.immediate { await accept(accepted) }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("pendingShare"))]
    )
  }

  @Test func ifLetShorthandThenClearThroughSelf() {
    assertLint(
      UseOptionalTake.self,
      """
      func f() {
        if 1️⃣let token {
          self.token = nil
          use(token)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("token"))]
    )
  }

  @Test func guardLetThenClear() {
    assertLint(
      UseOptionalTake.self,
      """
      func f() {
        guard 1️⃣let handler = self.handler else { return }
        self.handler = nil
        handler()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("handler"))]
    )
  }

  @Test func letThenClear() {
    assertLint(
      UseOptionalTake.self,
      """
      func f() {
        1️⃣let old = state.pending
        state.pending = nil
        finish(old)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("state.pending"))]
    )
  }

  @Test func extraConditionNotFlagged() {
    // `take()` clears the storage even when the second condition fails.
    assertLint(
      UseOptionalTake.self,
      """
      func f() {
        if let value = cache, value.isValid {
          cache = nil
        }
      }
      """,
      findings: []
    )
  }

  @Test func clearLaterOrElsewhereNotFlagged() {
    assertLint(
      UseOptionalTake.self,
      """
      func f() {
        if let value = cache {
          use(value)
          cache = nil
        }
        let other = first
        second = nil
        let computed = makeValue()
        computed2 = nil
      }
      """,
      findings: []
    )
  }

  @Test func takeAlreadyUsedNotFlagged() {
    assertLint(
      UseOptionalTake.self,
      """
      func f() {
        if let value = cache.take() {
          use(value)
        }
      }
      """,
      findings: []
    )
  }
}
