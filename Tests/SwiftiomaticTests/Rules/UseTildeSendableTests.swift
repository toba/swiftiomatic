@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseTildeSendableTests: RuleTesting {
  private static let message =
    "an unavailable 'Sendable' conformance is inherited, so no subclass can opt in — declare the type ': ~Sendable' instead (SE-0518)"

  @Test func unavailableSendableExtensionFlagged() {
    assertLint(
      UseTildeSendable.self,
      """
      @available(*, unavailable)
      extension Base: 1️⃣Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func uncheckedSendableFlagged() {
    assertLint(
      UseTildeSendable.self,
      """
      @available(*, unavailable)
      extension Base: 1️⃣@unchecked Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func messageArgumentStillFlagged() {
    assertLint(
      UseTildeSendable.self,
      """
      @available(*, unavailable, message: "holds a lock")
      extension Base: 1️⃣Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func platformScopedUnavailableNotFlagged() {
    assertLint(
      UseTildeSendable.self,
      """
      @available(macOS, unavailable)
      extension Base: Sendable {}
      """,
      findings: []
    )
  }

  @Test func plainSendableExtensionNotFlagged() {
    assertLint(
      UseTildeSendable.self,
      """
      extension Base: Sendable {}
      """,
      findings: []
    )
  }

  @Test func unavailableNonSendableExtensionNotFlagged() {
    assertLint(
      UseTildeSendable.self,
      """
      @available(*, unavailable)
      extension Base: Equatable {}
      """,
      findings: []
    )
  }

  @Test func tildeSendableDeclarationNotFlagged() {
    assertLint(
      UseTildeSendable.self,
      """
      public class Base: ~Sendable {}
      """,
      findings: []
    )
  }
}
