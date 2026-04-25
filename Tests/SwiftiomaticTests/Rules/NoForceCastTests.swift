@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoForceCastTests: RuleTesting {

  @Test func forceCastDiagnosed() {
    assertFormatting(
      NoForceCast.self,
      input: """
        let x = value 1️⃣as! Int
        let y = something() 2️⃣as! String
        """,
      expected: """
        let x = value as! Int
        let y = something() as! String
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force cast to 'Int'"),
        FindingSpec("2️⃣", message: "do not force cast to 'String'"),
      ]
    )
  }

  @Test func conditionalCastNotDiagnosed() {
    assertFormatting(
      NoForceCast.self,
      input: """
        let x = value as? Int
        let y = value as String
        """,
      expected: """
        let x = value as? Int
        let y = value as String
        """,
      findings: []
    )
  }

  @Test func forceCastInChain() {
    assertFormatting(
      NoForceCast.self,
      input: """
        let s = (value 1️⃣as! NSString).length
        """,
      expected: """
        let s = (value as! NSString).length
        """,
      findings: [
        FindingSpec("1️⃣", message: "do not force cast to 'NSString'"),
      ]
    )
  }
}
