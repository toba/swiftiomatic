@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoParensInClosureParamsTests: RuleTesting {
  @Test func singleParamRemoveParens() {
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        let f = { 1️⃣(x) in x + 1 }
        """,
      expected: """
        let f = { x in x + 1 }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove parentheses around closure parameters; shorthand form is preferred"
        ),
      ]
    )
  }

  @Test func multipleParamsRemoveParens() {
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        let f = { 1️⃣(x, y) in x + y }
        """,
      expected: """
        let f = { x, y in x + y }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove parentheses around closure parameters; shorthand form is preferred"
        ),
      ]
    )
  }

  @Test func wildcardSecondParam() {
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        let f = { 1️⃣(x, _) in x }
        """,
      expected: """
        let f = { x, _ in x }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove parentheses around closure parameters; shorthand form is preferred"
        ),
      ]
    )
  }

  @Test func typedParamsKeepParens() {
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        let f = { (x: Int, y: Int) in x + y }
        """,
      expected: """
        let f = { (x: Int, y: Int) in x + y }
        """,
      findings: []
    )
  }

  @Test func mixedTypedKeepParens() {
    // If any parameter has a type, the rule must not strip — shorthand can't carry types.
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        let f = { (x: Int, y) in x }
        """,
      expected: """
        let f = { (x: Int, y) in x }
        """,
      findings: []
    )
  }

  @Test func emptyParensNotFlagged() {
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        let f = { () -> Void in print("hi") }
        """,
      expected: """
        let f = { () -> Void in print("hi") }
        """,
      findings: []
    )
  }

  @Test func captureListUnaffected() {
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        foo.bar { [weak self] 1️⃣(x, y) in x + y }
        """,
      expected: """
        foo.bar { [weak self] x, y in x + y }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove parentheses around closure parameters; shorthand form is preferred"
        ),
      ]
    )
  }

  @Test func returnTypePreserved() {
    assertFormatting(
      NoParensInClosureParams.self,
      input: """
        let f = { 1️⃣(x) -> Bool in x > 0 }
        """,
      expected: """
        let f = { x -> Bool in x > 0 }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove parentheses around closure parameters; shorthand form is preferred"
        ),
      ]
    )
  }
}
