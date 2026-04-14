@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct AndOperatorTests: RuleTesting {
  @Test func ifWithAnd() {
    assertFormatting(
      AndOperator.self,
      input: """
        if a 1️⃣&& b {}
        """,
      expected: """
        if a, b {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func guardWithAnd() {
    assertFormatting(
      AndOperator.self,
      input: """
        guard a 1️⃣&& b else { return }
        """,
      expected: """
        guard a, b else { return }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func whileWithAnd() {
    assertFormatting(
      AndOperator.self,
      input: """
        while a 1️⃣&& b {}
        """,
      expected: """
        while a, b {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func chainedAnd() {
    assertFormatting(
      AndOperator.self,
      input: """
        if a 1️⃣&& b && c {}
        """,
      expected: """
        if a, b, c {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func orOperatorNotFlagged() {
    assertFormatting(
      AndOperator.self,
      input: """
        if a || b {}
        """,
      expected: """
        if a || b {}
        """,
      findings: []
    )
  }

  @Test func mixedOrAndNotFlagged() {
    // `a && b || c` folds to `(a && b) || c` — top-level is ||
    assertFormatting(
      AndOperator.self,
      input: """
        if a && b || c {}
        """,
      expected: """
        if a && b || c {}
        """,
      findings: []
    )
  }

  @Test func commaAlreadyUsed() {
    assertFormatting(
      AndOperator.self,
      input: """
        if a, b {}
        """,
      expected: """
        if a, b {}
        """,
      findings: []
    )
  }

  @Test func optionalBindingNotFlagged() {
    assertFormatting(
      AndOperator.self,
      input: """
        if let x = foo {}
        """,
      expected: """
        if let x = foo {}
        """,
      findings: []
    )
  }

  @Test func andNotInCondition() {
    assertFormatting(
      AndOperator.self,
      input: """
        let x = a && b
        """,
      expected: """
        let x = a && b
        """,
      findings: []
    )
  }

  @Test func parenthesizedOrWithAnd() {
    // `(a || b) && c` — top-level is &&, should flag
    assertFormatting(
      AndOperator.self,
      input: """
        if (a || b) 1️⃣&& c {}
        """,
      expected: """
        if (a || b), c {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func mixedCommaAndAnd() {
    // `if let x = foo, a && b {}` — only the second condition element has &&
    assertFormatting(
      AndOperator.self,
      input: """
        if let x = foo, a 1️⃣&& b {}
        """,
      expected: """
        if let x = foo, a, b {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func andParensReplaced() {
    // Parenthesized && inside should NOT be split (only top-level)
    assertFormatting(
      AndOperator.self,
      input: """
        if true 1️⃣&& (true && true) {}
        """,
      expected: """
        if true, (true && true) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func caseLetAndNotReplaced() {
    // `case let` binding uses && as part of the pattern expression
    assertFormatting(
      AndOperator.self,
      input: """
        if case let a = foo && bar {}
        """,
      expected: """
        if case let a = foo && bar {}
        """,
      findings: []
    )
  }

  @Test func ifLetAndNotReplaced() {
    // `let a = b && c` — && is in a binding expression, not a top-level condition
    assertFormatting(
      AndOperator.self,
      input: """
        if let a = b && c, let d = e && f {}
        """,
      expected: """
        if let a = b && c, let d = e && f {}
        """,
      findings: []
    )
  }

  @Test func functionCallAndReplaced() {
    assertFormatting(
      AndOperator.self,
      input: """
        if functionReturnsBool() 1️⃣&& true {}
        """,
      expected: """
        if functionReturnsBool(), true {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func andInsideFunction() {
    assertFormatting(
      AndOperator.self,
      input: """
        func someFunc() { if bar 1️⃣&& baz {} }
        """,
      expected: """
        func someFunc() { if bar, baz {} }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer ',' over '&&' in condition list"),
      ]
    )
  }

  @Test func noReplaceOrAnd() {
    // `foo || bar && baz` folds to `foo || (bar && baz)` — top-level is ||
    assertFormatting(
      AndOperator.self,
      input: """
        if foo || bar && baz {}
        """,
      expected: """
        if foo || bar && baz {}
        """,
      findings: []
    )
  }

  @Test func noReplaceAndOr() {
    // `foo && bar || baz` folds to `(foo && bar) || baz` — top-level is ||
    assertFormatting(
      AndOperator.self,
      input: """
        if foo && bar || baz {}
        """,
      expected: """
        if foo && bar || baz {}
        """,
      findings: []
    )
  }
}
