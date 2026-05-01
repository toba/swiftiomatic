@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseCompoundAssignmentTests: RuleTesting {

  @Test func plusAssignment() {
    assertFormatting(
      UseCompoundAssignment.self,
      input: """
        1️⃣foo = foo + 1
        """,
      expected: """
        foo += 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer compound assignment '+='"),
      ]
    )
  }

  @Test func multiplyAssignment() {
    assertFormatting(
      UseCompoundAssignment.self,
      input: """
        1️⃣foo = foo * aVariable
        """,
      expected: """
        foo *= aVariable
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer compound assignment '*='"),
      ]
    )
  }

  @Test func memberAccessLHS() {
    assertFormatting(
      UseCompoundAssignment.self,
      input: """
        1️⃣foo.aProperty = foo.aProperty - 1
        """,
      expected: """
        foo.aProperty -= 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer compound assignment '-='"),
      ]
    )
  }

  @Test func mismatchedSidesNotChanged() {
    assertFormatting(
      UseCompoundAssignment.self,
      input: """
        foo = bar + 1
        foo = self.foo + 1
        foo = aMethod(foo / bar)
        """,
      expected: """
        foo = bar + 1
        foo = self.foo + 1
        foo = aMethod(foo / bar)
        """,
      findings: []
    )
  }

  @Test func leadingIndentationPreserved() {
    assertFormatting(
      UseCompoundAssignment.self,
      input: """
        func step() {
            1️⃣n = n + i / outputLength
        }
        """,
      expected: """
        func step() {
            n += i / outputLength
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer compound assignment '+='"),
      ]
    )
  }
}
