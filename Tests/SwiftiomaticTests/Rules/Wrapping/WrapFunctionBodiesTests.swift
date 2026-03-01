import Testing

@testable import Swiftiomatic

@Suite struct WrapFunctionBodiesTests {
  // MARK: - Functions

  @Test func wrapSingleLineFunctionBody() {
    let input = """
      func foo() { print("bar") }
      """
    let output = """
      func foo() {
          print("bar")
      }
      """
    testFormatting(for: input, output, rule: .wrapFunctionBodies)
  }

  @Test func wrapFunctionWithReturnStatement() {
    let input = """
      func getValue() -> Int { return 42 }
      """
    let output = """
      func getValue() -> Int {
          return 42
      }
      """
    testFormatting(for: input, output, rule: .wrapFunctionBodies)
  }

  @Test func doesNotWrapAlreadyMultilineFunction() {
    let input = """
      func foo() {
          print("bar")
      }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies)
  }

  @Test func doesNotWrapEmptyFunctionBody() {
    let input = """
      func foo() {}
      """
    testFormatting(for: input, rule: .wrapFunctionBodies)
  }

  @Test func wrapFunctionWithSomeReturnType() {
    let input = """
      func foo() -> some View { Text("hello") }
      """
    let output = """
      func foo() -> some View {
          Text("hello")
      }
      """
    testFormatting(for: input, output, rule: .wrapFunctionBodies)
  }

  // MARK: - Initializers

  @Test func wrapSingleLineInit() {
    let input = """
      init() { value = 0 }
      """
    let output = """
      init() {
          value = 0
      }
      """
    testFormatting(for: input, output, rule: .wrapFunctionBodies)
  }

  @Test func wrapFailableInit() {
    let input = """
      init?() { return nil }
      """
    let output = """
      init?() {
          return nil
      }
      """
    testFormatting(for: input, output, rule: .wrapFunctionBodies)
  }

  // MARK: - Subscripts

  @Test func wrapSingleLineSubscript() {
    let input = """
      subscript(index: Int) -> Int { array[index] }
      """
    let output = """
      subscript(index: Int) -> Int {
          array[index]
      }
      """
    testFormatting(for: input, output, rule: .wrapFunctionBodies)
  }

  // MARK: - Closures (should NOT be wrapped)

  @Test func doesNotWrapClosure() {
    let input = """
      let closure = { print("hello") }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies)
  }

  @Test func doesNotWrapClosureAsArgument() {
    let input = """
      array.map { $0 * 2 }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies)
  }

  // MARK: - Computed Properties (should NOT be wrapped by this rule)

  @Test func doesNotWrapComputedProperty() {
    let input = """
      var bar: String { "bar" }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies, exclude: [.wrapPropertyBodies])
  }

  // MARK: - Protocols

  @Test func doesNotWrapFunctionDeclarationInProtocol() {
    let input = """
      protocol Foo {
          func bar() -> String
      }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies)
  }

  @Test func doesNotWrapSubscriptDeclarationInProtocol() {
    let input = """
      protocol Foo {
          subscript(index: Int) -> Int { get }
      }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies, exclude: [.unusedArguments])
  }

  @Test func doesNotWrapInitDeclarationInProtocol() {
    let input = """
      protocol Foo {
          init()
      }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies)
  }

  @Test func doesNotWrapDefaultImplementationInProtocol() {
    let input = """
      protocol Foo {
          func bar() -> String { "bar" }
      }
      """
    testFormatting(for: input, rule: .wrapFunctionBodies)
  }

  // MARK: - Edge Cases

  @Test func wrapFunctionInClass() {
    let input = """
      class Foo {
          func bar() { print("baz") }
      }
      """
    let output = """
      class Foo {
          func bar() {
              print("baz")
          }
      }
      """
    testFormatting(for: input, output, rule: .wrapFunctionBodies)
  }
}
