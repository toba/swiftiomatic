@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantPropertyTests: RuleTesting {

  // MARK: - Conversions

  @Test func basicLetThenReturn() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Int {
            1️⃣let result = 42
            return result
        }
        """,
      expected: """
        func foo() -> Int {
            return 42
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'result' property; return the expression directly")
      ])
  }

  @Test func expressionInitializer() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> String {
            1️⃣let text = bar() + baz()
            return text
        }
        """,
      expected: """
        func foo() -> String {
            return bar() + baz()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'text' property; return the expression directly")
      ])
  }

  @Test func removesRedundantVariableFollowingOtherVariable() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Foo {
            let bar = Bar(baaz: baaz)
            1️⃣let foo = Foo(bar: bar)
            return foo
        }
        """,
      expected: """
        func foo() -> Foo {
            let bar = Bar(baaz: baaz)
            return Foo(bar: bar)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'foo' property; return the expression directly")
      ])
  }

  @Test func removesRedundantVariableWithFunctionCall() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Foo {
            1️⃣let foo = Foo(bar: bar, baaz: baaz)
            return foo
        }
        """,
      expected: """
        func foo() -> Foo {
            return Foo(bar: bar, baaz: baaz)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'foo' property; return the expression directly")
      ])
  }

  // MARK: - No-ops

  @Test func differentNameNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Int {
            let result = 42
            return other
        }
        """,
      expected: """
        func foo() -> Int {
            let result = 42
            return other
        }
        """)
  }

  @Test func varNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Int {
            var result = 42
            return result
        }
        """,
      expected: """
        func foo() -> Int {
            var result = 42
            return result
        }
        """)
  }

  @Test func withTypeAnnotationNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Int {
            let result: Int = 42
            return result
        }
        """,
      expected: """
        func foo() -> Int {
            let result: Int = 42
            return result
        }
        """)
  }

  @Test func nonConsecutiveNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Int {
            let result = 42
            print(result)
            return result
        }
        """,
      expected: """
        func foo() -> Int {
            let result = 42
            print(result)
            return result
        }
        """)
  }

  @Test func returnWithoutLetNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Int {
            return 42
        }
        """,
      expected: """
        func foo() -> Int {
            return 42
        }
        """)
  }

  @Test func multipleBindingsNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Int {
            let a = 1, b = 2
            return a
        }
        """,
      expected: """
        func foo() -> Int {
            let a = 1, b = 2
            return a
        }
        """)
  }

  @Test func returnWithMethodCallNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() -> Foo {
            let foo = Foo(bar: bar)
            return foo.with(quux: quux)
        }
        """,
      expected: """
        func foo() -> Foo {
            let foo = Foo(bar: bar)
            return foo.with(quux: quux)
        }
        """)
  }

  @Test func returnWithPropertyAccessNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func bar() -> Foo {
            let bar = Bar(baaz: baaz)
            return bar.baaz
        }
        """,
      expected: """
        func bar() -> Foo {
            let bar = Bar(baaz: baaz)
            return bar.baaz
        }
        """)
  }

  @Test func propertyUsedBeforeReturnNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func baaz() -> Foo {
            let bar = Bar(baaz: baaz)
            print(bar)
            return bar
        }
        """,
      expected: """
        func baaz() -> Foo {
            let bar = Bar(baaz: baaz)
            print(bar)
            return bar
        }
        """)
  }

  @Test func returnWithNoExpressionNotFlagged() {
    assertFormatting(
      DropRedundantProperty.self,
      input: """
        func foo() {
            let result = 42
            return
        }
        """,
      expected: """
        func foo() {
            let result = 42
            return
        }
        """)
  }
}
