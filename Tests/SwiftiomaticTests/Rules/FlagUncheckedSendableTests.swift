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

  /// The compiler refuses a subclass that drops an inherited `@unchecked Sendable`, so a warning
  /// there asks for a change that does not compile.
  @Test func exemptSuperclassSubclassNotFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class HoistAwait: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {}
      """,
      findings: [],
      configuration: Self.exempting("StaticFormatRule")
    )
  }

  @Test func exemptSuperclassMatchedWithoutGenericArguments() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class Rule: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {}
      """,
      findings: [],
      configuration: Self.exempting("LintSyntaxRule")
    )
  }

  @Test func unlistedSuperclassStillFlagged() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class Cache: NSObject, 1️⃣@unchecked Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)],
      configuration: Self.exempting("StaticFormatRule")
    )
  }

  @Test func rootClassStillFlaggedWhenListIsSet() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      final class Cache: 1️⃣@unchecked Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)],
      configuration: Self.exempting("StaticFormatRule")
    )
  }

  @Test func extensionStillFlaggedWhenListIsSet() {
    assertLint(
      FlagUncheckedSendable.self,
      """
      extension StaticFormatRule: 1️⃣@unchecked Sendable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)],
      configuration: Self.exempting("StaticFormatRule")
    )
  }

  private static func exempting(_ name: String) -> Configuration {
    var configuration = Configuration.forTesting(enabledRule: FlagUncheckedSendable.key)
    var value = configuration[FlagUncheckedSendable.self]
    value.sendableSuperclasses = [name]
    configuration[FlagUncheckedSendable.self] = value
    return configuration
  }
}
