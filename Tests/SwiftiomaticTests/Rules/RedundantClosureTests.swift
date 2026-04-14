@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantClosureTests: RuleTesting {
  @Test func singleExpression() {
    assertLint(
      RedundantClosure.self,
      """
      let x = 1️⃣{ 42 }()
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly"),
      ]
    )
  }

  @Test func singleReturn() {
    assertLint(
      RedundantClosure.self,
      """
      let x = 1️⃣{ return 42 }()
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly"),
      ]
    )
  }

  @Test func multipleStatementsNotFlagged() {
    assertLint(
      RedundantClosure.self,
      """
      let x = {
        let a = 1
        return a + 1
      }()
      """,
      findings: []
    )
  }

  @Test func closureWithParametersNotFlagged() {
    assertLint(
      RedundantClosure.self,
      """
      let x = { (a: Int) in a + 1 }(42)
      """,
      findings: []
    )
  }

  @Test func closureWithCaptureNotFlagged() {
    assertLint(
      RedundantClosure.self,
      """
      let x = { [weak self] in self?.value }()
      """,
      findings: []
    )
  }

  @Test func nonIIFENotFlagged() {
    assertLint(
      RedundantClosure.self,
      """
      let closure = { 42 }
      """,
      findings: []
    )
  }

  @Test func functionCallNotFlagged() {
    assertLint(
      RedundantClosure.self,
      """
      let x = foo()
      """,
      findings: []
    )
  }

  @Test func complexExpression() {
    assertLint(
      RedundantClosure.self,
      """
      let x = 1️⃣{ someObject.property }()
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly"),
      ]
    )
  }
}
