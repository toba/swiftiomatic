@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantPatternTests: RuleTesting {

  // MARK: - If case patterns

  @Test func removeRedundantPatternInIfCase() {
    assertFormatting(
      RedundantPattern.self,
      input: """
        if case let .foo1️⃣(_, _) = bar {}
        """,
      expected: """
        if case .foo = bar {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant pattern matching; all associated values are discarded"),
      ]
    )
  }

  @Test func noRemoveRequiredPatternInIfCase() {
    // Tuple pattern without enum case — not redundant
    assertFormatting(
      RedundantPattern.self,
      input: """
        if case (_, _) = bar {}
        """,
      expected: """
        if case (_, _) = bar {}
        """,
      findings: []
    )
  }

  // MARK: - Switch case patterns

  @Test func removeRedundantPatternInSwitchCase() {
    assertFormatting(
      RedundantPattern.self,
      input: """
        switch foo {
        case let .bar1️⃣(_, _): break
        default: break
        }
        """,
      expected: """
        switch foo {
        case .bar: break
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant pattern matching; all associated values are discarded"),
      ]
    )
  }

  @Test func noRemoveRequiredPatternLetInSwitchCase() {
    // Has a non-wildcard binding — not redundant
    assertFormatting(
      RedundantPattern.self,
      input: """
        switch foo {
        case let .bar(_, a): break
        default: break
        }
        """,
      expected: """
        switch foo {
        case let .bar(_, a): break
        default: break
        }
        """,
      findings: []
    )
  }

  @Test func noRemoveRequiredPatternInSwitchCase() {
    // Tuple pattern without enum case — not redundant
    assertFormatting(
      RedundantPattern.self,
      input: """
        switch foo {
        case (_, _): break
        default: break
        }
        """,
      expected: """
        switch foo {
        case (_, _): break
        default: break
        }
        """,
      findings: []
    )
  }

  // MARK: - Let/var bindings

  @Test func simplifyLetTuplePattern() {
    assertFormatting(
      RedundantPattern.self,
      input: """
        let 1️⃣(_, _) = bar
        """,
      expected: """
        let _ = bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace tuple of wildcards with a single wildcard"),
      ]
    )
  }

  // MARK: - No false positives

  @Test func noRemoveVoidFunctionCall() {
    // .foo() with empty parens is not redundant pattern matching
    assertFormatting(
      RedundantPattern.self,
      input: """
        if case .foo() = bar {}
        """,
      expected: """
        if case .foo() = bar {}
        """,
      findings: []
    )
  }

  @Test func noRemoveMethodSignature() {
    // Function parameters, not pattern matching
    assertFormatting(
      RedundantPattern.self,
      input: """
        func foo(_, _) {}
        """,
      expected: """
        func foo(_, _) {}
        """,
      findings: []
    )
  }

  // MARK: - Per-argument let/var wildcards

  @Test func removePerArgBareWildcard() {
    assertFormatting(
      RedundantPattern.self,
      input: """
        switch foo {
        case .bar1️⃣(_): break
        default: break
        }
        """,
      expected: """
        switch foo {
        case .bar: break
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant pattern matching; all associated values are discarded"),
      ]
    )
  }

  @Test func removePerArgLetWildcards() {
    assertFormatting(
      RedundantPattern.self,
      input: """
        switch foo {
        case .bar1️⃣(let _, let _): break
        default: break
        }
        """,
      expected: """
        switch foo {
        case .bar: break
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant pattern matching; all associated values are discarded"),
      ]
    )
  }

  @Test func noRemovePerArgWithNamedBinding() {
    // Has a named binding — not all wildcards
    assertFormatting(
      RedundantPattern.self,
      input: """
        switch foo {
        case .bar(let _, let x): break
        default: break
        }
        """,
      expected: """
        switch foo {
        case .bar(let _, let x): break
        default: break
        }
        """,
      findings: []
    )
  }

  @Test func singleWildcardInEnumCase() {
    assertFormatting(
      RedundantPattern.self,
      input: """
        switch foo {
        case let .bar1️⃣(_): break
        default: break
        }
        """,
      expected: """
        switch foo {
        case .bar: break
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant pattern matching; all associated values are discarded"),
      ]
    )
  }
}
