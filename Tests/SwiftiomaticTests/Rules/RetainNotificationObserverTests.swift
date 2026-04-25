@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RetainNotificationObserverTests: RuleTesting {
  @Test func discardedAddObserverWithTrailingClosure() {
    assertLint(
      RetainNotificationObserver.self,
      """
      1️⃣nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }
      """,
      findings: [
        FindingSpec("1️⃣", message: "store the observer returned by addObserver(forName:object:queue:) so it can be removed later"),
      ]
    )
  }

  @Test func explicitDiscardStillFlagged() {
    assertLint(
      RetainNotificationObserver.self,
      """
      _ = 1️⃣nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }
      """,
      findings: [
        FindingSpec("1️⃣", message: "store the observer returned by addObserver(forName:object:queue:) so it can be removed later"),
      ]
    )
  }

  @Test func usingTrailingClosureLabel() {
    assertLint(
      RetainNotificationObserver.self,
      """
      1️⃣nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
      """,
      findings: [
        FindingSpec("1️⃣", message: "store the observer returned by addObserver(forName:object:queue:) so it can be removed later"),
      ]
    )
  }

  @Test func assignedToBindingDoesNotTrigger() {
    assertLint(
      RetainNotificationObserver.self,
      """
      let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }
      """,
      findings: []
    )
  }

  @Test func returnedFromFunctionDoesNotTrigger() {
    assertLint(
      RetainNotificationObserver.self,
      """
      func foo() -> Any {
        return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
      }
      """,
      findings: []
    )
  }

  @Test func appendedToArrayDoesNotTrigger() {
    assertLint(
      RetainNotificationObserver.self,
      """
      var obs: [Any?] = []
      obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
      """,
      findings: []
    )
  }

  @Test func inArrayLiteralDoesNotTrigger() {
    assertLint(
      RetainNotificationObserver.self,
      """
      var obs: [NSObjectProtocol] = [
        nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }),
        nc.addObserver(forName: .CKAccountChanged, object: nil, queue: nil, using: { }),
      ]
      """,
      findings: []
    )
  }

  @Test func discardableResultMarkerDoesTrigger() {
    assertLint(
      RetainNotificationObserver.self,
      """
      @discardableResult func foo() -> Any {
        return 1️⃣nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "store the observer returned by addObserver(forName:object:queue:) so it can be removed later"),
      ]
    )
  }
}
