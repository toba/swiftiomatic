import Testing

@testable import Swiftiomatic

@Suite struct RedundantVoidReturnTypeTests {
  @Test func removeRedundantVoidReturnType() {
    let input = """
      func foo() -> Void {}
      """
    let output = """
      func foo() {}
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantVoidReturnType2() {
    let input = """
      func foo() ->
          Void {}
      """
    let output = """
      func foo() {}
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantSwiftDotVoidReturnType() {
    let input = """
      func foo() -> Swift.Void {}
      """
    let output = """
      func foo() {}
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantSwiftDotVoidReturnType2() {
    let input = """
      func foo() -> Swift
          .Void {}
      """
    let output = """
      func foo() {}
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantEmptyReturnType() {
    let input = """
      func foo() -> () {}
      """
    let output = """
      func foo() {}
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantVoidTupleReturnType() {
    let input = """
      func foo() -> (Void) {}
      """
    let output = """
      func foo() {}
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func noRemoveCommentFollowingRedundantVoidReturnType() {
    let input = """
      func foo() -> Void /* void */ {}
      """
    let output = """
      func foo() /* void */ {}
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func noRemoveRequiredVoidReturnType() {
    let input = """
      typealias Foo = () -> Void
      """
    testFormatting(for: input, rule: .redundantVoidReturnType)
  }

  @Test func noRemoveChainedVoidReturnType() {
    let input = """
      func foo() -> () -> Void {}
      """
    testFormatting(for: input, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantVoidInClosureArguments() {
    let input = """
      { (foo: Bar) -> Void in foo() }
      """
    let output = """
      { (foo: Bar) in foo() }
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantEmptyReturnTypeInClosureArguments() {
    let input = """
      { (foo: Bar) -> () in foo() }
      """
    let output = """
      { (foo: Bar) in foo() }
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantVoidInClosureArguments2() {
    let input = """
      methodWithTrailingClosure { foo -> Void in foo() }
      """
    let output = """
      methodWithTrailingClosure { foo in foo() }
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func removeRedundantSwiftDotVoidInClosureArguments2() {
    let input = """
      methodWithTrailingClosure { foo -> Swift.Void in foo() }
      """
    let output = """
      methodWithTrailingClosure { foo in foo() }
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func noRemoveRedundantVoidInClosureArgument() {
    let input = """
      { (foo: Bar) -> Void in foo() }
      """
    let options = FormatOptions(closureVoidReturn: .preserve)
    testFormatting(for: input, rule: .redundantVoidReturnType, options: options)
  }

  @Test func removeRedundantVoidInProtocolDeclaration() {
    let input = """
      protocol Foo {
          func foo() -> Void
          func bar() -> ()
          var baz: Int { get }
          func bazz() -> ( )
      }
      """

    let output = """
      protocol Foo {
          func foo()
          func bar()
          var baz: Int { get }
          func bazz()
      }
      """
    testFormatting(for: input, output, rule: .redundantVoidReturnType)
  }

  @Test func noRemoveThrowingClosureVoidReturnType() {
    // https://github.com/nicklockwood/SwiftFormat/issues/1978
    let input = """
      func foo(bar: Bar) -> () throws -> Void
      """
    testFormatting(for: input, rule: .redundantVoidReturnType)
  }

  @Test func noRemoveClosureVoidReturnType() {
    let input = """
      func foo(bar: Bar) -> () -> Void
      """
    testFormatting(for: input, rule: .redundantVoidReturnType)
  }

  @Test func noRemoveAsyncClosureVoidReturnType() {
    let input = """
      func foo(bar: Bar) -> () async -> Void
      """
    testFormatting(for: input, rule: .redundantVoidReturnType)
  }
}
