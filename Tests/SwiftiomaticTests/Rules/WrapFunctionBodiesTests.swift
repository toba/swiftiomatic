@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapFunctionBodiesTests: RuleTesting {

  // MARK: - Functions

  @Test func singleLineFunctionWraps() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        func foo() 1️⃣{ print("bar") }
        """,
      expected: """
        func foo() {
            print("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  @Test func functionWithReturnWraps() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        func getValue() -> Int 1️⃣{ return 42 }
        """,
      expected: """
        func getValue() -> Int {
            return 42
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  @Test func alreadyMultilineFunctionUnchanged() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        func foo() {
            print("bar")
        }
        """,
      expected: """
        func foo() {
            print("bar")
        }
        """)
  }

  @Test func emptyFunctionBodyUnchanged() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """)
  }

  @Test func functionWithSomeReturnTypeWraps() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        func foo() -> some View 1️⃣{ Text("hello") }
        """,
      expected: """
        func foo() -> some View {
            Text("hello")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  // MARK: - Initializers

  @Test func singleLineInitWraps() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        init() 1️⃣{ value = 0 }
        """,
      expected: """
        init() {
            value = 0
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  @Test func failableInitWraps() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        init?() 1️⃣{ return nil }
        """,
      expected: """
        init?() {
            return nil
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  // MARK: - Subscripts

  @Test func singleLineSubscriptWraps() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        subscript(index: Int) -> Int 1️⃣{ array[index] }
        """,
      expected: """
        subscript(index: Int) -> Int {
            array[index]
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  // MARK: - Should NOT wrap

  @Test func closureNotWrapped() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        let closure = { print("hello") }
        """,
      expected: """
        let closure = { print("hello") }
        """)
  }

  @Test func closureAsArgumentNotWrapped() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        array.map { $0 * 2 }
        """,
      expected: """
        array.map { $0 * 2 }
        """)
  }

  @Test func computedPropertyNotWrapped() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        var bar: String { "bar" }
        """,
      expected: """
        var bar: String { "bar" }
        """)
  }

  @Test func protocolFunctionDeclarationNotWrapped() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        protocol Foo {
            func bar() -> String
        }
        """,
      expected: """
        protocol Foo {
            func bar() -> String
        }
        """)
  }

  @Test func protocolSubscriptDeclarationNotWrapped() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        protocol Foo {
            subscript(index: Int) -> Int { get }
        }
        """,
      expected: """
        protocol Foo {
            subscript(index: Int) -> Int { get }
        }
        """)
  }

  // MARK: - Indented context

  @Test func functionInClassWraps() {
    assertFormatting(
      WrapFunctionBodies.self,
      input: """
        class Foo {
            func bar() 1️⃣{ print("baz") }
        }
        """,
      expected: """
        class Foo {
            func bar() {
                print("baz")
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }
}
