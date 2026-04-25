@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantNilCoalescingTests: RuleTesting {
  @Test func basicCoalesceNil() {
    assertFormatting(
      RedundantNilCoalescing.self,
      input: """
        let result = x 1️⃣?? nil
        """,
      expected: """
        let result = x
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '?? nil'; the value is unchanged"),
      ]
    )
  }

  @Test func memberAccessLHS() {
    assertFormatting(
      RedundantNilCoalescing.self,
      input: """
        let r = obj.value 1️⃣?? nil
        """,
      expected: """
        let r = obj.value
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '?? nil'; the value is unchanged"),
      ]
    )
  }

  @Test func nonNilRHSNotFlagged() {
    assertFormatting(
      RedundantNilCoalescing.self,
      input: """
        let result = x ?? 0
        """,
      expected: """
        let result = x ?? 0
        """,
      findings: []
    )
  }

  @Test func otherOperatorNotFlagged() {
    assertFormatting(
      RedundantNilCoalescing.self,
      input: """
        let result = x + nil
        """,
      expected: """
        let result = x + nil
        """,
      findings: []
    )
  }

  @Test func nestedExpression() {
    assertFormatting(
      RedundantNilCoalescing.self,
      input: """
        return f(x 1️⃣?? nil)
        """,
      expected: """
        return f(x)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant '?? nil'; the value is unchanged"),
      ]
    )
  }
}
