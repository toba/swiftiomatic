@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantBackticksTests: RuleTesting {

  // MARK: - Basic removal

  @Test func removeRedundantBackticksInLet() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let 1️⃣`foo` = bar
        """,
      expected: """
        let foo = bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'foo'"),
      ]
    )
  }

  @Test func noRemoveBackticksAroundKeyword() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let `let` = foo
        """,
      expected: """
        let `let` = foo
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAroundSelf() {
    // `self` in binding position needs backticks (shadows self).
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let `self` = foo
        """,
      expected: """
        let `self` = foo
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAroundClassSelfInTypealias() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        typealias `Self` = Foo
        """,
      expected: """
        typealias `Self` = Foo
        """,
      findings: []
    )
  }

  // MARK: - Self/Any in type positions

  @Test func removeBackticksAroundClassSelfAsParameterType() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func foo(bar: 1️⃣`Self`) { print(bar) }
        """,
      expected: """
        func foo(bar: Self) { print(bar) }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'Self'"),
      ]
    )
  }

  @Test func removeBackticksAroundClassSelfAsReturnType() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func foo() -> 1️⃣`Self` {}
        """,
      expected: """
        func foo() -> Self {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'Self'"),
      ]
    )
  }

  // MARK: - Argument labels

  @Test func removeBackticksAroundClassSelfArgument() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func foo(1️⃣`Self`: Foo) { print(Self) }
        """,
      expected: """
        func foo(Self: Foo) { print(Self) }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'Self'"),
      ]
    )
  }

  @Test func noRemoveBackticksAroundKeywordFollowedByType() {
    // `default` as a variable name needs backticks.
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let `default`: Int = foo
        """,
      expected: """
        let `default`: Int = foo
        """,
      findings: []
    )
  }

  // MARK: - Accessor keywords

  @Test func noRemoveBackticksAroundContextualGet() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        var foo: Int {
            `get`()
            return 5
        }
        """,
      expected: """
        var foo: Int {
            `get`()
            return 5
        }
        """,
      findings: []
    )
  }

  @Test func removeBackticksAroundGetArgument() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func foo(1️⃣`get` value: Int) { print(value) }
        """,
      expected: """
        func foo(get value: Int) { print(value) }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'get'"),
      ]
    )
  }

  // MARK: - Type as identifier

  @Test func removeBackticksAroundTypeAtRootLevel() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        enum 1️⃣`Type` {}
        """,
      expected: """
        enum Type {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'Type'"),
      ]
    )
  }

  @Test func noRemoveBackticksAroundTypeInsideType() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        struct Foo {
            enum `Type` {}
        }
        """,
      expected: """
        struct Foo {
            enum `Type` {}
        }
        """,
      findings: []
    )
  }

  // MARK: - Let/var as argument labels

  @Test func noRemoveBackticksAroundLetArgument() {
    // `let` needs backticks even as argument labels.
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func foo(`let`: Foo) { print(`let`) }
        """,
      expected: """
        func foo(`let`: Foo) { print(`let`) }
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAroundTrueArgument() {
    // `true` is a keyword, needs backticks in label position (for safety).
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func foo(`true`: Foo) { print(`true`) }
        """,
      expected: """
        func foo(`true`: Foo) { print(`true`) }
        """,
      findings: []
    )
  }

  // MARK: - Member access (after dot)

  @Test func noRemoveBackticksAroundTypeProperty() {
    // `.Type` after `.` has special metatype meaning.
    assertFormatting(
      RedundantBackticks.self,
      input: """
        var type: Foo.`Type`
        """,
      expected: """
        var type: Foo.`Type`
        """,
      findings: []
    )
  }

  @Test func removeBackticksAroundProperty() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        var type = Foo.1️⃣`bar`
        """,
      expected: """
        var type = Foo.bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'bar'"),
      ]
    )
  }

  @Test func removeBackticksAroundKeywordProperty() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        var type = Foo.1️⃣`default`
        """,
      expected: """
        var type = Foo.default
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'default'"),
      ]
    )
  }

  @Test func removeBackticksAroundKeypathProperty() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        var type = \\.1️⃣`bar`
        """,
      expected: """
        var type = \\.bar
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'bar'"),
      ]
    )
  }

  @Test func removeBackticksAroundKeypathKeywordProperty() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        var type = \\.1️⃣`default`
        """,
      expected: """
        var type = \\.default
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'default'"),
      ]
    )
  }

  @Test func noRemoveBackticksAroundInitProperty() {
    // `.init` after dot has special initializer meaning.
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let foo: Foo = .`init`
        """,
      expected: """
        let foo: Foo = .`init`
        """,
      findings: []
    )
  }

  // MARK: - Enum cases

  @Test func noRemoveBackticksAroundAnyEnumCase() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        enum Foo {
            case `Any`
        }
        """,
      expected: """
        enum Foo {
            case `Any`
        }
        """,
      findings: []
    )
  }

  // MARK: - Subscript accessor keyword

  @Test func noRemoveBackticksAroundGetInSubscript() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        subscript<T>(_ name: String) -> T where T: Equatable {
            `get`(name)
        }
        """,
      expected: """
        subscript<T>(_ name: String) -> T where T: Equatable {
            `get`(name)
        }
        """,
      findings: []
    )
  }

  // MARK: - Actor keyword

  @Test func noRemoveBackticksAroundActorProperty() {
    // `actor` as a variable name in a declaration.
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let `actor`: Foo
        """,
      expected: """
        let `actor`: Foo
        """,
      findings: []
    )
  }

  @Test func removeBackticksAroundActorRvalue() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let foo = 1️⃣`actor`
        """,
      expected: """
        let foo = actor
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'actor'"),
      ]
    )
  }

  @Test func removeBackticksAroundActorLabel() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        init(1️⃣`actor`: Foo)
        """,
      expected: """
        init(actor: Foo)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'actor'"),
      ]
    )
  }

  @Test func removeBackticksAroundActorLabel2() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        init(1️⃣`actor` foo: Foo)
        """,
      expected: """
        init(actor foo: Foo)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'actor'"),
      ]
    )
  }

  // MARK: - Special cases

  @Test func noRemoveBackticksAroundUnderscore() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func `_`<T>(_ foo: T) -> T { foo }
        """,
      expected: """
        func `_`<T>(_ foo: T) -> T { foo }
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAroundShadowedSelf() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        struct Foo {
            let `self`: URL

            func printURL() {
                print("My URL is \\(self.`self`)")
            }
        }
        """,
      expected: """
        struct Foo {
            let `self`: URL

            func printURL() {
                print("My URL is \\(self.`self`)")
            }
        }
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAroundDollar() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        @attached(peer, names: prefixed(`$`))
        """,
      expected: """
        @attached(peer, names: prefixed(`$`))
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAroundRawIdentifier() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func `function with raw identifier`() -> String {
            "foo"
        }

        let `property with raw identifier` = `function with raw identifier`()
        """,
      expected: """
        func `function with raw identifier`() -> String {
            "foo"
        }

        let `property with raw identifier` = `function with raw identifier`()
        """,
      findings: []
    )
  }

  // MARK: - Module selector (::)

  @Test func removeBackticksAfterModuleSelector() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let x = NASA::1️⃣`default`
        """,
      expected: """
        let x = NASA::default
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'default'"),
      ]
    )
  }

  @Test func removeBackticksAfterModuleSelectorForKeyword() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let x = NASA::1️⃣`let`
        """,
      expected: """
        let x = NASA::let
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'let'"),
      ]
    )
  }

  @Test func noRemoveBackticksAfterModuleSelectorForInit() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let x = NASA::`init`
        """,
      expected: """
        let x = NASA::`init`
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAfterModuleSelectorForDeinit() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let x = NASA::`deinit`
        """,
      expected: """
        let x = NASA::`deinit`
        """,
      findings: []
    )
  }

  @Test func noRemoveBackticksAfterModuleSelectorForSubscript() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let x = NASA::`subscript`
        """,
      expected: """
        let x = NASA::`subscript`
        """,
      findings: []
    )
  }

  // MARK: - Contextual keywords

  @Test func removeBackticksAroundContextualKeyword() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let 1️⃣`async` = true
        """,
      expected: """
        let async = true
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'async'"),
      ]
    )
  }

  @Test func removeBackticksAroundFunctionName() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        func 1️⃣`myFunc`() {}
        """,
      expected: """
        func myFunc() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove unnecessary backticks around 'myFunc'"),
      ]
    )
  }

  @Test func noBackticksNotFlagged() {
    assertFormatting(
      RedundantBackticks.self,
      input: """
        let name = "hello"
        """,
      expected: """
        let name = "hello"
        """,
      findings: []
    )
  }
}
