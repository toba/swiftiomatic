import Testing

@testable import Swiftiomatic

@Suite struct VoidTests {
  @Test func emptyParensReturnValueConvertedToVoid() {
    let input = """
      () -> ()
      """
    let output = """
      () -> Void
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func spacedParensReturnValueConvertedToVoid() {
    let input = """
      () -> ( 
      )
      """
    let output = """
      () -> Void
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func parensContainingCommentNotConvertedToVoid() {
    let input = """
      () -> ( /* Hello World */ )
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func parensNotConvertedToVoidIfLocalOverrideExists() {
    let input = """
      struct Void {}
      let foo = () -> ()
      print(foo)
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func parensRemovedAroundVoid() {
    let input = """
      () -> (Void)
      """
    let output = """
      () -> Void
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func voidArgumentConvertedToEmptyParens() {
    let input = """
      Void -> Void
      """
    let output = """
      () -> Void
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func voidArgumentInParensNotConvertedToEmptyParens() {
    let input = """
      (Void) -> Void
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func anonymousVoidArgumentNotConvertedToEmptyParens() {
    let input = """
      { (_: Void) -> Void in }
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func funcWithAnonymousVoidArgumentNotStripped() {
    let input = """
      func foo(_: Void) -> Void
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func functionThatReturnsAFunction() {
    let input = """
      (Void) -> Void -> ()
      """
    let output = """
      (Void) -> () -> Void
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func functionThatReturnsAFunctionThatThrows() {
    let input = """
      (Void) -> Void throws -> ()
      """
    let output = """
      (Void) -> () throws -> Void
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func functionThatReturnsAFunctionThatHasTypedThrows() {
    let input = """
      (Void) -> Void throws(Foo) -> ()
      """
    let output = """
      (Void) -> () throws(Foo) -> Void
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func chainOfFunctionsIsNotChanged() {
    let input = """
      () -> () -> () -> Void
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func chainOfFunctionsWithThrowsIsNotChanged() {
    let input = """
      () -> () throws -> () throws -> Void
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func chainOfFunctionsWithTypedThrowsIsNotChanged() {
    let input = """
      () -> () throws(Foo) -> () throws(Foo) -> Void
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func voidThrowsIsNotMangled() {
    let input = """
      (Void) throws -> Void
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func voidTypedThrowsIsNotMangled() {
    let input = """
      (Void) throws(Foo) -> Void
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func emptyClosureArgsNotMangled() {
    let input = """
      { () in }
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func emptyClosureReturnValueConvertedToVoid() {
    let input = """
      { () -> () in }
      """
    let output = """
      { () -> Void in }
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func anonymousVoidClosureNotChanged() {
    let input = """
      { (_: Void) in }
      """
    testFormatting(for: input, rule: .void, exclude: [.unusedArguments])
  }

  @Test func voidLiteralConvertedToParens() {
    let input = """
      foo(Void())
      """
    let output = """
      foo(())
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func voidLiteralConvertedToParens2() {
    let input = """
      let foo = Void()
      """
    let output = """
      let foo = ()
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func voidLiteralReturnValueConvertedToParens() {
    let input = """
      func foo() {
          return Void()
      }
      """
    let output = """
      func foo() {
          return ()
      }
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func voidLiteralReturnValueConvertedToParens2() {
    let input = """
      { _ in Void() }
      """
    let output = """
      { _ in () }
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func namespacedVoidLiteralNotConverted() {
    // TODO: it should actually be safe to convert Swift.Void - only unsafe for other namespaces
    let input = """
      let foo = Swift.Void()
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func malformedFuncDoesNotCauseInvalidOutput() {
    let input = """
      func baz(Void) {}
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func emptyParensInGenericsConvertedToVoid() {
    let input = """
      Foo<(), ()>
      """
    let output = """
      Foo<Void, Void>
      """
    testFormatting(for: input, output, rule: .void)
  }

  @Test func caseVoidNotUnwrapped() {
    let input = """
      case some(Void)
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func localVoidTypeNotConverted() {
    let input = """
      struct Void {}
      let foo = Void()
      print(foo)
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func localVoidTypeForwardReferenceNotConverted() {
    let input = """
      let foo = Void()
      print(foo)
      struct Void {}
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func localVoidTypealiasNotConverted() {
    let input = """
      typealias Void = MyVoid
      let foo = Void()
      print(foo)
      """
    testFormatting(for: input, rule: .void)
  }

  @Test func localVoidTypealiasForwardReferenceNotConverted() {
    let input = """
      let foo = Void()
      print(foo)
      typealias Void = MyVoid
      """
    testFormatting(for: input, rule: .void)
  }

  // useVoid = false

  @Test func useVoidOptionFalse() {
    let input = """
      (Void) -> Void
      """
    let output = """
      (()) -> ()
      """
    let options = FormatOptions(useVoid: false)
    testFormatting(for: input, output, rule: .void, options: options)
  }

  @Test func namespacedVoidNotConverted() {
    let input = """
      () -> Swift.Void
      """
    let options = FormatOptions(useVoid: false)
    testFormatting(for: input, rule: .void, options: options)
  }

  @Test func typealiasVoidNotConverted() {
    let input = """
      public typealias Void = ()
      """
    let options = FormatOptions(useVoid: false)
    testFormatting(for: input, rule: .void, options: options)
  }

  @Test func voidClosureReturnValueConvertedToEmptyTuple() {
    let input = """
      { () -> Void in }
      """
    let output = """
      { () -> () in }
      """
    let options = FormatOptions(useVoid: false)
    testFormatting(
      for: input, output, rule: .void, options: options
    )
  }

  @Test func noConvertVoidSelfToTuple() {
    let input = """
      Void.self
      """
    let options = FormatOptions(useVoid: false)
    testFormatting(for: input, rule: .void, options: options)
  }

  @Test func noConvertVoidTypeToTuple() {
    let input = """
      Void.Type
      """
    let options = FormatOptions(useVoid: false)
    testFormatting(for: input, rule: .void, options: options)
  }

  @Test func caseVoidConvertedToTuple() {
    let input = """
      case some(Void)
      """
    let output = """
      case some(())
      """
    let options = FormatOptions(useVoid: false)
    testFormatting(for: input, output, rule: .void, options: options)
  }

  @Test func typealiasEmptyTupleConvertedToVoid() {
    let input = """
      public typealias Dependencies = ()
      """
    let output = """
      public typealias Dependencies = Void
      """
    testFormatting(for: input, output, rule: .void)
  }
}
