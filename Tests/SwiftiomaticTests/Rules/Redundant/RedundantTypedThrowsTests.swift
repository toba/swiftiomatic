@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantTypedThrowsTests: RuleTesting {
  @Test func throwsAnyError() {
    assertFormatting(
      RedundantTypedThrows.self,
      input: """
        func foo() 1️⃣throws(any Error) {}
        """,
      expected: """
        func foo() throws {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'throws(any Error)' with 'throws'"),
      ]
    )
  }

  @Test func throwsNever() {
    assertFormatting(
      RedundantTypedThrows.self,
      input: """
        func foo() 1️⃣throws(Never) {}
        """,
      expected: """
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'throws(Never)'; the function cannot throw"),
      ]
    )
  }

  @Test func plainThrowsNotFlagged() {
    assertFormatting(
      RedundantTypedThrows.self,
      input: """
        func foo() throws {}
        """,
      expected: """
        func foo() throws {}
        """,
      findings: []
    )
  }

  @Test func typedThrowsSpecificErrorNotFlagged() {
    assertFormatting(
      RedundantTypedThrows.self,
      input: """
        func foo() throws(MyError) {}
        """,
      expected: """
        func foo() throws(MyError) {}
        """,
      findings: []
    )
  }

  @Test func nonThrowingNotFlagged() {
    assertFormatting(
      RedundantTypedThrows.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: []
    )
  }

  @Test func closureThrowsAnyError() {
    assertFormatting(
      RedundantTypedThrows.self,
      input: """
        let f: () 1️⃣throws(any Error) -> Void = {}
        """,
      expected: """
        let f: () throws -> Void = {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'throws(any Error)' with 'throws'"),
      ]
    )
  }
}
