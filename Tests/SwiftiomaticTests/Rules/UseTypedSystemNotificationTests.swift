@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseTypedSystemNotificationTests: RuleTesting {
  private static func message(name: String, replacement: String) -> String {
    "'\(name)' has a typed adapter '\(replacement)' on OS 26+ — prefer 'addObserver(of:for:)' / 'messages(of:)' with the typed message"
  }

  @Test func uiApplicationAddObserverFlagged() {
    assertLint(
      UseTypedSystemNotification.self,
      """
      NotificationCenter.default.addObserver(
        forName: 1️⃣UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { _ in }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: Self.message(
            name: "UIApplication.willResignActiveNotification",
            replacement: "UIApplication.WillResignActiveMessage"
          )
        )
      ]
    )
  }

  @Test func notificationsNamedAsyncSequenceFlagged() {
    assertLint(
      UseTypedSystemNotification.self,
      """
      for await _ in NotificationCenter.default.notifications(named: 1️⃣UIApplication.didBecomeActiveNotification) {}
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: Self.message(
            name: "UIApplication.didBecomeActiveNotification",
            replacement: "UIApplication.DidBecomeActiveMessage"
          )
        )
      ]
    )
  }

  @Test func foundationLegacyBareNameFlagged() {
    assertLint(
      UseTypedSystemNotification.self,
      """
      NotificationCenter.default.addObserver(
        forName: 1️⃣NSUndoManagerDidCloseUndoGroup,
        object: nil,
        queue: .main
      ) { _ in }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: Self.message(
            name: "NSUndoManagerDidCloseUndoGroup",
            replacement: "UndoManager.DidCloseUndoGroupMessage"
          )
        )
      ]
    )
  }

  @Test func postNameFlagged() {
    assertLint(
      UseTypedSystemNotification.self,
      """
      NotificationCenter.default.post(name: 1️⃣UIApplication.didBecomeActiveNotification, object: nil)
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: Self.message(
            name: "UIApplication.didBecomeActiveNotification",
            replacement: "UIApplication.DidBecomeActiveMessage"
          )
        )
      ]
    )
  }

  @Test func nonAdaptedNotificationNotFlagged() {
    assertLint(
      UseTypedSystemNotification.self,
      """
      for await _ in NotificationCenter.default.notifications(named: NSView.boundsDidChangeNotification) {}
      """,
      findings: []
    )
  }

  @Test func customNotificationNotFlagged() {
    assertLint(
      UseTypedSystemNotification.self,
      """
      NotificationCenter.default.post(name: .myCustomThing, object: nil)
      """,
      findings: []
    )
  }
}
