@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PairAcquireWithDeferTests: RuleTesting {
  private static func message(_ acquire: String, _ release: String) -> String {
    "'\(acquire)' has no paired 'defer { \(release)() }' in this scope — a later 'return' or 'throw' will silently skip the cleanup"
  }

  @Test func beginEditingWithEarlyReturnFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func reload() {
        textStorage.1️⃣beginEditing()
        guard let items = source.items else { return }
        apply(items)
        textStorage.endEditing()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("beginEditing", "endEditing"))]
    )
  }

  @Test func beginEditingWithDeferNotFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func reload() {
        textStorage.beginEditing()
        defer { textStorage.endEditing() }
        guard let items = source.items else { return }
        apply(items)
      }
      """,
      findings: []
    )
  }

  @Test func straightLineWithoutEarlyExitNotFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func draw() {
        ctx.saveGState()
        ctx.draw(thing)
        ctx.restoreGState()
      }
      """,
      findings: []
    )
  }

  @Test func lockWithThrowFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func step() throws {
        m.1️⃣lock()
        try work()
        m.unlock()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("lock", "unlock"))]
    )
  }

  @Test func objcSyncEnterFreeFunctionFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func go(_ obj: AnyObject) {
        1️⃣objc_sync_enter(obj)
        guard ok else { return }
        objc_sync_exit(obj)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("objc_sync_enter", "objc_sync_exit"))]
    )
  }

  @Test func securityScopedResourceFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func read(_ url: URL) {
        url.1️⃣startAccessingSecurityScopedResource()
        guard let data = try? Data(contentsOf: url) else { return }
        process(data)
        url.stopAccessingSecurityScopedResource()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("startAccessingSecurityScopedResource", "stopAccessingSecurityScopedResource"))]
    )
  }

  @Test func earlyExitInsideNestedClosureDoesNotCount() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func draw() {
        ctx.saveGState()
        items.forEach { item in
          guard item.visible else { return }
          item.draw()
        }
        ctx.restoreGState()
      }
      """,
      findings: []
    )
  }

  @Test func acquireInsideClosureFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func go() {
        run {
          ctx.1️⃣saveGState()
          guard ok else { return }
          ctx.restoreGState()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("saveGState", "restoreGState"))]
    )
  }

  @Test func deferBeforeAcquireDoesNotPair() {
    // A defer above the acquire pairs nothing in this scope. Flag the acquire.
    assertLint(
      PairAcquireWithDefer.self,
      """
      func a() {
        defer { other.endEditing() }
        textStorage.1️⃣beginEditing()
        guard ok else { return }
        textStorage.endEditing()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("beginEditing", "endEditing"))]
    )
  }

  @Test func unknownPairNotFlagged() {
    assertLint(
      PairAcquireWithDefer.self,
      """
      func go() {
        thing.startSomething()
        guard ok else { return }
        thing.stopSomething()
      }
      """,
      findings: []
    )
  }
}
