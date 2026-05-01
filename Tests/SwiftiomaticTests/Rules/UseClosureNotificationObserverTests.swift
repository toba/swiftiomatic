@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseClosureNotificationObserverTests: RuleTesting {
  @Test func selectorBasedFlagged() {
    assertLint(
      UseClosureNotificationObserver.self,
      """
      1️⃣NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleEvent),
        name: .someNotification,
        object: nil
      )
      """,
      findings: [
        FindingSpec("1️⃣", message: "selector-based 'addObserver' requires '@objc' and manual cleanup — prefer closure-based 'addObserver(forName:object:queue:using:)' or 'NotificationCenter.Message'"),
      ]
    )
  }

  @Test func closureBasedNotFlagged() {
    assertLint(
      UseClosureNotificationObserver.self,
      """
      let token = NotificationCenter.default.addObserver(
        forName: .someNotification,
        object: nil,
        queue: .main
      ) { note in
        print(note)
      }
      """,
      findings: []
    )
  }

  @Test func nonNotificationCenterAddObserverNotFlagged() {
    assertLint(
      UseClosureNotificationObserver.self,
      """
      KVO.observe(self, keyPath: "x", options: [.new])
      """,
      findings: []
    )
  }
}
