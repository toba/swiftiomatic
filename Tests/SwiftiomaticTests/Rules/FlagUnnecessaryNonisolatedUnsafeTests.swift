import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagUnnecessaryNonisolatedUnsafeTests: RuleTesting {
  private static let message =
    "'nonisolated(unsafe)' is not needed on a 'let' initialized with a literal — the value is already 'Sendable'"

  @Test func integerLiteralFlagged() {
    assertLint(
      FlagUnnecessaryNonisolatedUnsafe.self,
      """
      1️⃣nonisolated(unsafe) let maximumRetryCount = 3
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func stringLiteralFlagged() {
    assertLint(
      FlagUnnecessaryNonisolatedUnsafe.self,
      """
      1️⃣nonisolated(unsafe) let separator = ", "
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func arrayLiteralFlagged() {
    assertLint(
      FlagUnnecessaryNonisolatedUnsafe.self,
      """
      1️⃣nonisolated(unsafe) let allowedPorts: [Int] = [80, 443]
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func mutableGlobalNotFlagged() {
    assertLint(
      FlagUnnecessaryNonisolatedUnsafe.self,
      """
      nonisolated(unsafe) var requestCount = 0
      """,
      findings: []
    )
  }

  @Test func constructedValueNotFlagged() {
    assertLint(
      FlagUnnecessaryNonisolatedUnsafe.self,
      """
      nonisolated(unsafe) let cache = NSCache<NSString, NSData>()
      """,
      findings: []
    )
  }

  @Test func plainLetNotFlagged() {
    assertLint(
      FlagUnnecessaryNonisolatedUnsafe.self,
      """
      let maximumRetryCount = 3
      """,
      findings: []
    )
  }
}
