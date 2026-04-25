@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoVoidTernaryTests: RuleTesting {

  @Test func voidTernaryAsStatement() {
    assertFormatting(
      NoVoidTernary.self,
      input: """
        func run() {
          success 1️⃣? doA() : doB()
        }
        """,
      expected: """
        func run() {
          success ? doA() : doB()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'if'/'else' instead of a ternary to call void-returning functions"),
      ]
    )
  }

  @Test func voidTernaryAtTopLevelStatement() {
    assertFormatting(
      NoVoidTernary.self,
      input: """
        func run() {
          flag 1️⃣? askQuestion() : exit()
          let x = 1
        }
        """,
      expected: """
        func run() {
          flag ? askQuestion() : exit()
          let x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'if'/'else' instead of a ternary to call void-returning functions"),
      ]
    )
  }

  @Test func ternaryAsValueNotDiagnosed() {
    assertFormatting(
      NoVoidTernary.self,
      input: """
        func price(_ hasDiscount: Bool) -> Double {
          return hasDiscount ? calculateDiscount() : calculateRegular()
        }
        let x = flag ? a() : b()
        foo(x == 2 ? a() : b())
        """,
      expected: """
        func price(_ hasDiscount: Bool) -> Double {
          return hasDiscount ? calculateDiscount() : calculateRegular()
        }
        let x = flag ? a() : b()
        foo(x == 2 ? a() : b())
        """,
      findings: []
    )
  }

  @Test func implicitReturnTernaryNotDiagnosed() {
    assertFormatting(
      NoVoidTernary.self,
      input: """
        var price: Double {
          hasDiscount ? calculateDiscount() : calculateRegular()
        }
        """,
      expected: """
        var price: Double {
          hasDiscount ? calculateDiscount() : calculateRegular()
        }
        """,
      findings: []
    )
  }
}
