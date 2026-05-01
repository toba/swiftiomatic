@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseIsDisjointTests: RuleTesting {

  @Test func intersectionDotIsEmpty() {
    assertFormatting(
      UseIsDisjoint.self,
      input: """
        _ = Set(syntaxKinds).1️⃣intersection(commentKinds).isEmpty
        """,
      expected: """
        _ = Set(syntaxKinds).intersection(commentKinds).isEmpty
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'isDisjoint(with:)' over 'intersection(_:).isEmpty'"),
      ]
    )
  }

  @Test func intersectionDotIsEmptyNegated() {
    assertFormatting(
      UseIsDisjoint.self,
      input: """
        let isObjc = !objcAttributes.1️⃣intersection(other).isEmpty
        """,
      expected: """
        let isObjc = !objcAttributes.intersection(other).isEmpty
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'isDisjoint(with:)' over 'intersection(_:).isEmpty'"),
      ]
    )
  }

  @Test func intersectionWithoutIsEmptyNotDiagnosed() {
    assertFormatting(
      UseIsDisjoint.self,
      input: """
        let r = Set(a).intersection(b)
        let s = !setA.intersection(setB).count == 0
        let t = setA.isDisjoint(with: setB)
        """,
      expected: """
        let r = Set(a).intersection(b)
        let s = !setA.intersection(setB).count == 0
        let t = setA.isDisjoint(with: setB)
        """,
      findings: []
    )
  }
}
