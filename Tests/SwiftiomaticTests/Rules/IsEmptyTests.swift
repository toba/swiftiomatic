@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct IsEmptyTests: RuleTesting {
  @Test func countEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.1️⃣count == 0 {}
        """,
      expected: """
        if foo.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func countNotEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.1️⃣count != 0 {}
        """,
      expected: """
        if !foo.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '!.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func countGreaterThanZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.1️⃣count > 0 {}
        """,
      expected: """
        if !foo.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '!.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func optionalChainCountEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo?.1️⃣count == 0 {}
        """,
      expected: """
        if foo?.isEmpty == true {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty == true' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func optionalChainCountNotEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo?.1️⃣count != 0 {}
        """,
      expected: """
        if foo?.isEmpty != true {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty != true' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func yodaCountEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if 0 == foo.1️⃣count {}
        """,
      expected: """
        if foo.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func yodaZeroLessThanCount() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if 0 < foo.1️⃣count {}
        """,
      expected: """
        if !foo.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '!.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func chainedMemberAccess() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.bar.1️⃣count == 0 {}
        """,
      expected: """
        if foo.bar.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func countComparedToNonZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.count == 1 {}
        if foo.count > 5 {}
        if foo.count != 3 {}
        """,
      expected: """
        if foo.count == 1 {}
        if foo.count > 5 {}
        if foo.count != 3 {}
        """,
      findings: []
    )
  }

  @Test func countWithoutComparison() {
    assertFormatting(
      IsEmpty.self,
      input: """
        let n = foo.count
        print(foo.count)
        """,
      expected: """
        let n = foo.count
        print(foo.count)
        """,
      findings: []
    )
  }

  @Test func isEmptyAlreadyUsed() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.isEmpty {}
        if !foo.isEmpty {}
        """,
      expected: """
        if foo.isEmpty {}
        if !foo.isEmpty {}
        """,
      findings: []
    )
  }

  @Test func countLessThanZeroIgnored() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.count < 0 {}
        """,
      expected: """
        if foo.count < 0 {}
        """,
      findings: []
    )
  }

  @Test func multipleViolations() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo.1️⃣count == 0 && bar.2️⃣count > 0 {}
        """,
      expected: """
        if foo.isEmpty && !bar.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty' over comparing 'count' to zero"),
        FindingSpec("2️⃣", message: "prefer '!.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func functionCallCountEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo().1️⃣count == 0 {}
        """,
      expected: """
        if foo().isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func countGreaterThanZeroAfterOpenParen() {
    assertFormatting(
      IsEmpty.self,
      input: """
        foo(bar.1️⃣count > 0)
        """,
      expected: """
        foo(!bar.isEmpty)
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '!.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func countGreaterThanZeroAfterArgumentLabel() {
    assertFormatting(
      IsEmpty.self,
      input: """
        foo(bar: baz.1️⃣count > 0)
        """,
      expected: """
        foo(bar: !baz.isEmpty)
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '!.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func countExpressionGreaterThanZeroNotTransformed() {
    // `a.count - b.count > 0` is arithmetic, not a simple count check
    assertFormatting(
      IsEmpty.self,
      input: """
        if a.count - b.count > 0 {}
        """,
      expected: """
        if a.count - b.count > 0 {}
        """,
      findings: []
    )
  }

  @Test func optionalChainedPropertyCountEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo?.bar.1️⃣count == 0 {}
        """,
      expected: """
        if foo?.bar.isEmpty == true {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty == true' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func compoundIfCountEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo, bar.1️⃣count == 0 {}
        """,
      expected: """
        if foo, bar.isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func functionCallCountNotEqualsZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo().1️⃣count != 0 {}
        """,
      expected: """
        if !foo().isEmpty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '!.isEmpty' over comparing 'count' to zero"),
      ]
    )
  }

  @Test func optionalChainCountGreaterThanZero() {
    assertFormatting(
      IsEmpty.self,
      input: """
        if foo?.1️⃣count > 0 {}
        """,
      expected: """
        if foo?.isEmpty != true {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '.isEmpty != true' over comparing 'count' to zero"),
      ]
    )
  }
}
