import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireProtocolSuffixConventionTests: RuleTesting {
  private static func capability(_ name: String, _ suggestion: String) -> String {
    "the guidelines name a capability with 'able' — rename '\(name)' to '\(suggestion)'"
  }

  private static func ongoing(_ name: String, _ suggestion: String) -> String {
    "the guidelines name an ongoing action with 'ing' — rename '\(name)' to '\(suggestion)'"
  }

  @Test func ingCapabilityFlagged() {
    assertLint(
      RequireProtocolSuffixConvention.self,
      """
      protocol 1️⃣Hashing {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.capability("Hashing", "Hashable"))]
    )
  }

  @Test func prefixedIngCapabilityFlagged() {
    assertLint(
      RequireProtocolSuffixConvention.self,
      """
      protocol 1️⃣PayloadEncoding {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.capability("PayloadEncoding", "PayloadEncodable"))]
    )
  }

  @Test func ableOngoingActionFlagged() {
    assertLint(
      RequireProtocolSuffixConvention.self,
      """
      protocol 1️⃣ProgressReportable {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.ongoing("ProgressReportable", "ProgressReporting"))]
    )
  }

  @Test func conventionalNamesNotFlagged() {
    assertLint(
      RequireProtocolSuffixConvention.self,
      """
      protocol ProgressReporting {}
      protocol Equatable {}
      protocol Collection {}
      """,
      findings: []
    )
  }

  @Test func typeDeclarationNotFlagged() {
    assertLint(
      RequireProtocolSuffixConvention.self,
      """
      struct Hashing {}
      final class ProgressReportable {}
      """,
      findings: []
    )
  }
}
