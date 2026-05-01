@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireRetainOfNotificationObserverTests: RuleTesting {
  @Test func discardedAddObserverWithTrailingClosure() {
    assertLint(
      RequireRetainOfNotificationObserver.self,
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
      RequireRetainOfNotificationObserver.self,
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
      RequireRetainOfNotificationObserver.self,
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
      RequireRetainOfNotificationObserver.self,
      """
      let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }
      """,
      findings: []
    )
  }

  @Test func returnedFromFunctionDoesNotTrigger() {
    assertLint(
      RequireRetainOfNotificationObserver.self,
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
      RequireRetainOfNotificationObserver.self,
      """
      var obs: [Any?] = []
      obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
      """,
      findings: []
    )
  }

  @Test func inArrayLiteralDoesNotTrigger() {
    assertLint(
      RequireRetainOfNotificationObserver.self,
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
      RequireRetainOfNotificationObserver.self,
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
