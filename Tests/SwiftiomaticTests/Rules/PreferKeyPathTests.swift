@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferKeyPathTests: RuleTesting {
  @Test func mapWithTrailingClosure() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.map 1️⃣{ $0.name }
        """,
      expected: """
        let names = items.map(\\.name)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }

  @Test func compactMapWithTrailingClosure() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.compactMap 1️⃣{ $0.optionalName }
        """,
      expected: """
        let names = items.compactMap(\\.optionalName)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'compactMap'"),
      ]
    )
  }

  @Test func filterWithTrailingClosure() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let active = items.filter 1️⃣{ $0.isActive }
        """,
      expected: """
        let active = items.filter(\\.isActive)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'filter'"),
      ]
    )
  }

  @Test func mapWithParenthesizedClosure() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.map(1️⃣{ $0.name })
        """,
      expected: """
        let names = items.map(\\.name)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }

  @Test func chainedPropertyAccess() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.map 1️⃣{ $0.foo.bar }
        """,
      expected: """
        let names = items.map(\\.foo.bar)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }

  @Test func containsWhereWithClosure() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let has = items.contains(where: 1️⃣{ $0.isValid })
        """,
      expected: """
        let has = items.contains(where: \\.isValid)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'contains(where:)'"),
      ]
    )
  }

  @Test func mapWithComplexClosure() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.map { $0.name.uppercased() }
        """,
      expected: """
        let names = items.map { $0.name.uppercased() }
        """,
      findings: []
    )
  }

  @Test func mapWithNamedParameter() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.map { item in item.name }
        """,
      expected: """
        let names = items.map { item in item.name }
        """,
      findings: []
    )
  }

  @Test func mapWithMultipleStatements() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.map {
          let x = $0.name
          return x
        }
        """,
      expected: """
        let names = items.map {
          let x = $0.name
          return x
        }
        """,
      findings: []
    )
  }

  @Test func keyPathAlreadyUsed() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let names = items.map(\\.name)
        """,
      expected: """
        let names = items.map(\\.name)
        """,
      findings: []
    )
  }

  @Test func containsWithoutWhere() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let has = items.contains { $0.isValid }
        """,
      expected: """
        let has = items.contains { $0.isValid }
        """,
      findings: []
    )
  }

  @Test func unrelatedMethod() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let x = items.forEach { $0.doSomething }
        """,
      expected: """
        let x = items.forEach { $0.doSomething }
        """,
      findings: []
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func bareDollarZeroNotConverted() {
    // `{ $0 }` is not a property access — don't convert
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let foo = bar.map { $0 }
        """,
      expected: """
        let foo = bar.map { $0 }
        """,
      findings: []
    )
  }

  @Test func methodCallNotConverted() {
    // `$0.foo()` is a method call, not a property access
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let foo = bar.map { $0.foo() }
        """,
      expected: """
        let foo = bar.map { $0.foo() }
        """,
      findings: []
    )
  }

  @Test func optionalChainingNotConverted() {
    // `$0?.foo` uses optional chaining — don't convert
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let foo = bar.map { $0?.foo }
        """,
      expected: """
        let foo = bar.map { $0?.foo }
        """,
      findings: []
    )
  }

  @Test func compoundExpressionNotConverted() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let foo = bar.map { $0.foo || baz }
        """,
      expected: """
        let foo = bar.map { $0.foo || baz }
        """,
      findings: []
    )
  }

  @Test func multipleTrailingClosuresNotConverted() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        foo.map { $0.bar } reverse: { $0.bar }
        """,
      expected: """
        foo.map { $0.bar } reverse: { $0.bar }
        """,
      findings: []
    )
  }

  @Test func multilineClosureConverted() {
    assertFormatting(
      PreferKeyPath.self,
      input: """
        let foo = bar.map 1️⃣{
            $0.foo
        }
        """,
      expected: """
        let foo = bar.map(\\.foo)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use keyPath expression instead of closure in 'map'"),
      ]
    )
  }
}
