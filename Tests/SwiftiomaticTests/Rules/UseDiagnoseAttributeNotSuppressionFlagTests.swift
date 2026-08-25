@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseDiagnoseAttributeNotSuppressionFlagTests: RuleTesting {
  private static func message(_ flag: String) -> String {
    "'\(flag)' changes diagnostics for the whole module — scope it with '@diagnose(GroupID, as: ignored)' (SE-0522) on the declaration that needs it"
  }

  @Test func suppressWarningsFlagged() {
    assertLint(
      UseDiagnoseAttributeNotSuppressionFlag.self,
      """
      let settings: [SwiftSetting] = [
        .unsafeFlags([1️⃣"-suppress-warnings"])
      ]
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("-suppress-warnings"))]
    )
  }

  @Test func warningGroupFlagsFlagged() {
    assertLint(
      UseDiagnoseAttributeNotSuppressionFlag.self,
      """
      let settings: [SwiftSetting] = [
        .unsafeFlags([1️⃣"-Wwarning", "DeprecatedDeclaration", 2️⃣"-Werror", "StrictMemorySafety"])
      ]
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("-Wwarning")),
        FindingSpec("2️⃣", message: Self.message("-Werror")),
      ]
    )
  }

  @Test func otherUnsafeFlagNotFlagged() {
    assertLint(
      UseDiagnoseAttributeNotSuppressionFlag.self,
      """
      let settings: [SwiftSetting] = [
        .unsafeFlags(["-enable-bare-slash-regex"])
      ]
      """,
      findings: []
    )
  }

  @Test func flagStringOutsideUnsafeFlagsNotFlagged() {
    assertLint(
      UseDiagnoseAttributeNotSuppressionFlag.self,
      """
      let documentation = "-suppress-warnings"
      """,
      findings: []
    )
  }

  @Test func diagnoseAttributeNotFlagged() {
    assertLint(
      UseDiagnoseAttributeNotSuppressionFlag.self,
      """
      @diagnose(DeprecatedDeclaration, as: ignored)
      func legacy() {}
      """,
      findings: []
    )
  }
}
