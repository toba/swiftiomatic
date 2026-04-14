@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantTypedThrowsTests: RuleTesting {
  @Test func throwsAnyError() {
    assertLint(
      RedundantTypedThrows.self,
      """
      func foo() 1️⃣throws(any Error) {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'throws(any Error)' with 'throws'"),
      ]
    )
  }

  @Test func throwsNever() {
    assertLint(
      RedundantTypedThrows.self,
      """
      func foo() 1️⃣throws(Never) {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'throws(Never)'; the function cannot throw"),
      ]
    )
  }

  @Test func plainThrowsNotFlagged() {
    assertLint(
      RedundantTypedThrows.self,
      """
      func foo() throws {}
      """,
      findings: []
    )
  }

  @Test func typedThrowsSpecificErrorNotFlagged() {
    assertLint(
      RedundantTypedThrows.self,
      """
      func foo() throws(MyError) {}
      """,
      findings: []
    )
  }

  @Test func nonThrowingNotFlagged() {
    assertLint(
      RedundantTypedThrows.self,
      """
      func foo() {}
      """,
      findings: []
    )
  }

  @Test func closureThrowsAnyError() {
    assertLint(
      RedundantTypedThrows.self,
      """
      let f: () 1️⃣throws(any Error) -> Void = {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'throws(any Error)' with 'throws'"),
      ]
    )
  }
}
