@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagUncheckedSendableTests: RuleTesting {
  private static let message =
    "'@unchecked Sendable' bypasses data-race verification — review whether actor isolation, 'Mutex', or 'sending' would let the compiler check it"

  @Test func classUncheckedSendableFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class Cache: 1️⃣@unchecked Sendable {
        var storage: [String: Int] = [:]
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func extensionUncheckedSendableFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      extension Foo: 1️⃣@unchecked Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func uncheckedSendableAmongOthersFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class Cache: NSObject, 1️⃣@unchecked Sendable, Identifiable {
        let id = UUID()
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func qualifiedUncheckedSendableFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class Cache: 1️⃣@unchecked Swift.Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func plainSendableNotFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      struct Token: Sendable {
        let value: Int
      }
      """,
      findings: []
    )
  }

  @Test func uncheckedOnNonSendableProtocolNotFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class Foo: @unchecked Equatable {
        static func == (lhs: Foo, rhs: Foo) -> Bool { true }
      }
      """,
      findings: []
    )
  }
}
