@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct InsertBlankLineBetweenScopesTests: RuleTesting {

  @Test func blankLineBetweenFunctions() {
    assertFormatting(
      InsertBlankLineBetweenScopes.self,
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
      InsertBlankLineBetweenScopes.self,
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
      InsertBlankLineBetweenScopes.self,
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
      InsertBlankLineBetweenScopes.self,
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
      InsertBlankLineBetweenScopes.self,
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
      InsertBlankLineBetweenScopes.self,
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
      InsertBlankLineBetweenScopes.self,
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
      InsertBlankLineBetweenScopes.self,
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

  @Test func closingBraceAsBlankLineSkipsInsertion() {
    var config = Configuration.forTesting(enabledRule: InsertBlankLineBetweenScopes.self.key)
    config[TreatClosingBraceAsBlankLine.self] = true

    assertFormatting(
      InsertBlankLineBetweenScopes.self,
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
      findings: [],
      configuration: config
    )
  }

  @Test func closingBraceAsBlankLineDefaultStillInserts() {
    assertFormatting(
      InsertBlankLineBetweenScopes.self,
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

  @Test func closingBraceAsBlankLineMemberBlock() {
    var config = Configuration.forTesting(enabledRule: InsertBlankLineBetweenScopes.self.key)
    config[TreatClosingBraceAsBlankLine.self] = true

    assertFormatting(
      InsertBlankLineBetweenScopes.self,
      input: """
        struct Foo {
            func bar() {
                print("bar")
            }
            func baz() {
                print("baz")
            }
        }
        """,
      expected: """
        struct Foo {
            func bar() {
                print("bar")
            }
            func baz() {
                print("baz")
            }
        }
        """,
      findings: [],
      configuration: config
    )
  }

  @Test func commentAsBlankLineSkipsInsertion() {
    var config = Configuration.forTesting(enabledRule: InsertBlankLineBetweenScopes.self.key)
    config[TreatCommentAsBlankLine.self] = true

    assertFormatting(
      InsertBlankLineBetweenScopes.self,
      input: """
        func foo() {
            print("foo")
        }
        /// Does bar things.
        func bar() {
            print("bar")
        }
        """,
      expected: """
        func foo() {
            print("foo")
        }
        /// Does bar things.
        func bar() {
            print("bar")
        }
        """,
      findings: [],
      configuration: config
    )
  }

  @Test func commentAsBlankLineDefaultStillInserts() {
    assertFormatting(
      InsertBlankLineBetweenScopes.self,
      input: """
        func foo() {
            print("foo")
        }
        /// Does bar things.
        1️⃣func bar() {
            print("bar")
        }
        """,
      expected: """
        func foo() {
            print("foo")
        }

        /// Does bar things.
        func bar() {
            print("bar")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after scoped declaration"),
      ]
    )
  }

  @Test func commentAsBlankLineMemberBlock() {
    var config = Configuration.forTesting(enabledRule: InsertBlankLineBetweenScopes.self.key)
    config[TreatCommentAsBlankLine.self] = true

    assertFormatting(
      InsertBlankLineBetweenScopes.self,
      input: """
        struct Foo {
            func bar() {
                print("bar")
            }
            // Next function
            func baz() {
                print("baz")
            }
        }
        """,
      expected: """
        struct Foo {
            func bar() {
                print("bar")
            }
            // Next function
            func baz() {
                print("baz")
            }
        }
        """,
      findings: [],
      configuration: config
    )
  }

  @Test func noBlankLineBetweenProtocolMethods() {
    assertFormatting(
      InsertBlankLineBetweenScopes.self,
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
