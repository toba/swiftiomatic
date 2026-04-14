@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct AssertionFailuresTests: RuleTesting {
  @Test func assertFalseNoMessage() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        1️⃣assert(false)
        """,
      expected: """
        assertionFailure()
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'assert(false, ...)' with 'assertionFailure(...)'"),
      ]
    )
  }

  @Test func assertFalseWithMessage() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        1️⃣assert(false, "unexpected state")
        """,
      expected: """
        assertionFailure("unexpected state")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'assert(false, ...)' with 'assertionFailure(...)'"),
      ]
    )
  }

  @Test func preconditionFalseNoMessage() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        1️⃣precondition(false)
        """,
      expected: """
        preconditionFailure()
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'precondition(false, ...)' with 'preconditionFailure(...)'"),
      ]
    )
  }

  @Test func preconditionFalseWithMessage() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        1️⃣precondition(false, "should not reach here")
        """,
      expected: """
        preconditionFailure("should not reach here")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'precondition(false, ...)' with 'preconditionFailure(...)'"),
      ]
    )
  }

  @Test func assertTrueNotModified() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        assert(true)
        assert(x > 0)
        """,
      expected: """
        assert(true)
        assert(x > 0)
        """,
      findings: []
    )
  }

  @Test func preconditionTrueNotModified() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        precondition(x != nil)
        """,
      expected: """
        precondition(x != nil)
        """,
      findings: []
    )
  }

  @Test func assertionFailureNotModified() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        assertionFailure("already correct")
        preconditionFailure("already correct")
        """,
      expected: """
        assertionFailure("already correct")
        preconditionFailure("already correct")
        """,
      findings: []
    )
  }

  @Test func unrelatedFunctionNotModified() {
    assertFormatting(
      AssertionFailures.self,
      input: """
        myAssert(false)
        """,
      expected: """
        myAssert(false)
        """,
      findings: []
    )
  }
}
