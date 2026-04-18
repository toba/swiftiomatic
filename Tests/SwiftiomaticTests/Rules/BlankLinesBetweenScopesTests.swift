@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLinesBetweenScopesTests: RuleTesting {

  @Test func blankLineBetweenFunctions() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        func foo() {
            print("foo")
        }
        1️⃣func bar() {
            print("bar")
        }
        """,
      expected: """
        func foo() {
            print("foo")
        }

        func bar() {
            print("bar")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after scoped declaration"),
      ]
    )
  }

  @Test func noBlankLineBetweenPropertyAndFunction() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        var foo: Int
        func bar() {
            print("bar")
        }
        """,
      expected: """
        var foo: Int
        func bar() {
            print("bar")
        }
        """,
      findings: []
    )
  }

  @Test func blankLineIsBeforeComment() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        func foo() {
            print("foo")
        }
        /// headerdoc
        1️⃣func bar() {
            print("bar")
        }
        """,
      expected: """
        func foo() {
            print("foo")
        }

        /// headerdoc
        func bar() {
            print("bar")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after scoped declaration"),
      ]
    )
  }

  @Test func noExtraBlankLineBetweenFunctions() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        func foo() {
            print("foo")
        }

        func bar() {
            print("bar")
        }
        """,
      expected: """
        func foo() {
            print("foo")
        }

        func bar() {
            print("bar")
        }
        """,
      findings: []
    )
  }

  @Test func blankLineBetweenTypesInMemberBlock() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        struct Outer {
            struct Inner {
                var x: Int
            }
            1️⃣struct Another {
                var y: Int
            }
        }
        """,
      expected: """
        struct Outer {
            struct Inner {
                var x: Int
            }

            struct Another {
                var y: Int
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after scoped declaration"),
      ]
    )
  }

  @Test func noBlankLineBetweenInlineFunctions() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        class Foo {
            func foo() { print("foo") }
            func bar() { print("bar") }
        }
        """,
      expected: """
        class Foo {
            func foo() { print("foo") }
            func bar() { print("bar") }
        }
        """,
      findings: []
    )
  }

  @Test func noBlankLineBetweenIfStatements() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        func foo() {
            if x {
                print("x")
            }
            if y {
                print("y")
            }
        }
        """,
      expected: """
        func foo() {
            if x {
                print("x")
            }
            if y {
                print("y")
            }
        }
        """,
      findings: []
    )
  }

  @Test func blankLineAfterProtocolBeforeProperty() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        protocol Foo {
            func bar()
        }
        1️⃣var baz: String
        """,
      expected: """
        protocol Foo {
            func bar()
        }

        var baz: String
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after scoped declaration"),
      ]
    )
  }

  @Test func noBlankLineBetweenProtocolMethods() {
    assertFormatting(
      BlankLinesBetweenScopes.self,
      input: """
        protocol Foo {
            func bar()
            func baz() -> Int
        }
        """,
      expected: """
        protocol Foo {
            func bar()
            func baz() -> Int
        }
        """,
      findings: []
    )
  }
}
