@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoLiteralProtocolInitTests: RuleTesting {
  @Test func setArrayLiteralInitTriggers() {
    assertLint(
      NoLiteralProtocolInit.self,
      """
      let set = 1️⃣Set(arrayLiteral: 1, 2)
      """,
      findings: [
        FindingSpec("1️⃣", message: "initializers declared in compiler protocol 'ExpressibleByArrayLiteral' shouldn't be called directly"),
      ]
    )
  }

  @Test func explicitInitFormTriggers() {
    assertLint(
      NoLiteralProtocolInit.self,
      """
      let set = 1️⃣Set.init(arrayLiteral: 1, 2)
      """,
      findings: [
        FindingSpec("1️⃣", message: "initializers declared in compiler protocol 'ExpressibleByArrayLiteral' shouldn't be called directly"),
      ]
    )
  }

  @Test func dictionaryLiteralInitTriggers() {
    assertLint(
      NoLiteralProtocolInit.self,
      """
      let d = 1️⃣Dictionary(dictionaryLiteral: ("a", 1))
      """,
      findings: [
        FindingSpec("1️⃣", message: "initializers declared in compiler protocol 'ExpressibleByDictionaryLiteral' shouldn't be called directly"),
      ]
    )
  }

  @Test func ordinaryInitDoesNotTrigger() {
    assertLint(
      NoLiteralProtocolInit.self,
      """
      let set: Set<Int> = [1, 2]
      let copy = Set(array)
      """,
      findings: []
    )
  }

  @Test func wrongTypeWithSameLabelDoesNotTrigger() {
    // Only the listed standard library / Foundation types are flagged.
    assertLint(
      NoLiteralProtocolInit.self,
      """
      let s = MyCustomSet(arrayLiteral: 1, 2)
      """,
      findings: []
    )
  }
}
