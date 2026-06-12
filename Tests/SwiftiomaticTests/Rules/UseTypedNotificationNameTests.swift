@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseTypedNotificationNameTests: RuleTesting {
  private static let message =
    "custom 'Notification.Name' is pre-OS 26 — prefer a 'NotificationCenter.MainActorMessage' (or 'AsyncMessage') struct for type- and isolation-safety"

  @Test func extensionDeclarationFlagged() {
    assertLint(
      UseTypedNotificationName.self,
      """
      extension 1️⃣Notification.Name {
        static let mything = Self("com.app.mything")
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func rawValueConstructionFlagged() {
    assertLint(
      UseTypedNotificationName.self,
      """
      let name = 1️⃣Notification.Name(rawValue: "foo")
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func stringLiteralConstructionFlagged() {
    assertLint(
      UseTypedNotificationName.self,
      """
      let name = 1️⃣Notification.Name("foo")
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func unrelatedExtensionNotFlagged() {
    assertLint(
      UseTypedNotificationName.self,
      """
      extension String {
        static let foo = "bar"
      }
      """,
      findings: []
    )
  }

  @Test func unrelatedNameTypeNotFlagged() {
    assertLint(
      UseTypedNotificationName.self,
      """
      let n = Other.Name("foo")
      """,
      findings: []
    )
  }
}
