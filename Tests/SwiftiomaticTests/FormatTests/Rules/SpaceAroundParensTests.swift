import Testing

@testable import Swiftiomatic

@Suite struct SpaceAroundParensTests {
  @Test func spaceAfterSet() {
    let input = """
      private(set)var foo: Int
      """
    let output = """
      private(set) var foo: Int
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenParenAndClass() {
    let input = """
      @objc(XYZFoo)class foo
      """
    let output = """
      @objc(XYZFoo) class foo
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenConventionAndBlock() {
    let input = """
      @convention(block)() -> Void
      """
    let output = """
      @convention(block) () -> Void
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenConventionAndEscaping() {
    let input = """
      @convention(block)@escaping () -> Void
      """
    let output = """
      @convention(block) @escaping () -> Void
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenAutoclosureEscapingAndBlock() {  // Swift 2.3 only
    let input = """
      @autoclosure(escaping)() -> Void
      """
    let output = """
      @autoclosure(escaping) () -> Void
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenSendableAndBlock() {
    let input = """
      @Sendable (Action) -> Void
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenMainActorAndBlock() {
    let input = """
      @MainActor (Action) -> Void
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenMainActorAndBlock2() {
    let input = """
      @MainActor (@MainActor (Action) -> Void) async -> Void
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenMainActorAndClosureParams() {
    let input = """
      { @MainActor (foo: Int) in foo }
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenUncheckedAndSendable() {
    let input = """
      enum Foo: @unchecked Sendable {
          case bar
      }
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenParenAndAs() {
    let input = """
      (foo.bar) as? String
      """
    testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
  }

  @Test func noSpaceAfterParenAtEndOfFile() {
    let input = """
      (foo.bar)
      """
    testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
  }

  @Test func spaceBetweenParenAndFoo() {
    let input = """
      func foo ()
      """
    let output = """
      func foo()
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenParenAndAny() {
    let input = """
      func any ()
      """
    let output = """
      func any()
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenParenAndAnyType() {
    let input = """
      let foo: any(A & B).Type
      """
    let output = """
      let foo: any (A & B).Type
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenParenAndSomeType() {
    let input = """
      func foo() -> some(A & B).Type
      """
    let output = """
      func foo() -> some (A & B).Type
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noSpaceBetweenParenAndInit() {
    let input = """
      init ()
      """
    let output = """
      init()
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noSpaceBetweenObjcAndSelector() {
    let input = """
      @objc (XYZFoo) class foo
      """
    let output = """
      @objc(XYZFoo) class foo
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noSpaceBetweenHashSelectorAndBrace() {
    let input = """
      #selector(foo)
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func noSpaceBetweenHashKeyPathAndBrace() {
    let input = """
      #keyPath (foo.bar)
      """
    let output = """
      #keyPath(foo.bar)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noSpaceBetweenHashAvailableAndBrace() {
    let input = """
      #available (iOS 9.0, *)
      """
    let output = """
      #available(iOS 9.0, *)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noSpaceBetweenPrivateAndSet() {
    let input = """
      private (set) var foo: Int
      """
    let output = """
      private(set) var foo: Int
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenLetAndTuple() {
    let input = """
      if let (foo, bar) = baz {}
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenIfAndCondition() {
    let input = """
      if(a || b) == true {}
      """
    let output = """
      if (a || b) == true {}
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noSpaceBetweenArrayLiteralAndParen() {
    let input = """
      [String] ()
      """
    let output = """
      [String]()
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenCaptureListAndArguments() {
    let input = """
      { [weak self](foo) in print(foo) }
      """
    let output = """
      { [weak self] (foo) in print(foo) }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantParens])
  }

  @Test func addSpaceBetweenCaptureListAndArguments2() {
    let input = """
      { [weak self]() -> Void in }
      """
    let output = """
      { [weak self] () -> Void in }
      """
    testFormatting(
      for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
  }

  @Test func addSpaceBetweenCaptureListAndArguments3() {
    let input = """
      { [weak self]() throws -> Void in }
      """
    let output = """
      { [weak self] () throws -> Void in }
      """
    testFormatting(
      for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
  }

  @Test func addSpaceBetweenCaptureListAndArguments4() {
    let input = """
      { [weak self](foo: @escaping(Bar?) -> Void) -> Baz? in foo }
      """
    let output = """
      { [weak self] (foo: @escaping (Bar?) -> Void) -> Baz? in foo }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenCaptureListAndArguments5() {
    let input = """
      { [weak self](foo: @autoclosure() -> String) -> Baz? in foo() }
      """
    let output = """
      { [weak self] (foo: @autoclosure () -> String) -> Baz? in foo() }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenCaptureListAndArguments6() {
    let input = """
      { [weak self](foo: @Sendable() -> String) -> Baz? in foo() }
      """
    let output = """
      { [weak self] (foo: @Sendable () -> String) -> Baz? in foo() }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenCaptureListAndArguments7() {
    let input = """
      Foo<Bar>(0) { [weak self]() -> Void in }
      """
    let output = """
      Foo<Bar>(0) { [weak self] () -> Void in }
      """
    testFormatting(
      for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
  }

  @Test func addSpaceBetweenCaptureListAndArguments8() {
    let input = """
      { [weak self]() throws(Foo) -> Void in }
      """
    let output = """
      { [weak self] () throws(Foo) -> Void in }
      """
    testFormatting(
      for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
  }

  @Test func addSpaceBetweenEscapingAndParenthesizedClosure() {
    let input = """
      @escaping(() -> Void)
      """
    let output = """
      @escaping (() -> Void)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenAutoclosureAndParenthesizedClosure() {
    let input = """
      @autoclosure(() -> String)
      """
    let output = """
      @autoclosure (() -> String)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceBetweenClosingParenAndOpenBrace() {
    let input = """
      func foo(){ foo }
      """
    let output = """
      func foo() { foo }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.wrapFunctionBodies])
  }

  @Test func noSpaceBetweenClosingBraceAndParens() {
    let input = """
      { block } ()
      """
    let output = """
      { block }()
      """
    testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantClosure])
  }

  @Test func dontRemoveSpaceBetweenOpeningBraceAndParens() {
    let input = """
      a = (b + c)
      """
    testFormatting(
      for: input, rule: .spaceAroundParens,
      exclude: [.redundantParens])
  }

  @Test func keywordAsIdentifierParensSpacing() {
    let input = """
      if foo.let (foo, bar) {}
      """
    let output = """
      if foo.let(foo, bar) {}
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceAfterInoutParam() {
    let input = """
      func foo(bar _: inout(Int, String)) {}
      """
    let output = """
      func foo(bar _: inout (Int, String)) {}
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceAfterEscapingAttribute() {
    let input = """
      func foo(bar: @escaping() -> Void)
      """
    let output = """
      func foo(bar: @escaping () -> Void)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func spaceAfterAutoclosureAttribute() {
    let input = """
      func foo(bar: @autoclosure () -> Void)
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func spaceAfterSendableAttribute() {
    let input = """
      func foo(bar: @Sendable () -> Void)
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func spaceBeforeTupleIndexArgument() {
    let input = """
      foo.1 (true)
      """
    let output = """
      foo.1(true)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func removeSpaceBetweenParenAndBracket() {
    let input = """
      let foo = bar[5] ()
      """
    let output = """
      let foo = bar[5]()
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func removeSpaceBetweenParenAndBracketInsideClosure() {
    let input = """
      let foo = bar { [Int] () }
      """
    let output = """
      let foo = bar { [Int]() }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenParenAndCaptureList() {
    let input = """
      let foo = bar { [self](foo: Int) in foo }
      """
    let output = """
      let foo = bar { [self] (foo: Int) in foo }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenParenAndAwait() {
    let input = """
      let foo = await(bar: 5)
      """
    let output = """
      let foo = await (bar: 5)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenParenAndAwaitForSwift5_5() {
    let input = """
      let foo = await(bar: 5)
      """
    let output = """
      let foo = await (bar: 5)
      """
    testFormatting(
      for: input, output, rule: .spaceAroundParens,
      options: FormatOptions(swiftVersion: "5.5"))
  }

  @Test func noAddSpaceBetweenParenAndAwaitForSwiftLessThan5_5() {
    let input = """
      let foo = await(bar: 5)
      """
    testFormatting(
      for: input, rule: .spaceAroundParens,
      options: FormatOptions(swiftVersion: "5.4.9"))
  }

  @Test func addSpaceBetweenParenAndUnsafe() {
    let input = """
      unsafe(["sudo"] + args).map { unsafe strdup($0) }
      """
    let output = """
      unsafe (["sudo"] + args).map { unsafe strdup($0) }
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noAddSpaceBetweenParenAndAwaitForSwiftLessThan6_2() {
    let input = """
      unsafe(["sudo"] + args).map { unsafe strdup($0) }
      """
    testFormatting(
      for: input, rule: .spaceAroundParens,
      options: FormatOptions(swiftVersion: "6.1"))
  }

  @Test func removeSpaceBetweenParenAndConsume() {
    let input = """
      let foo = consume (bar)
      """
    let output = """
      let foo = consume(bar)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func noAddSpaceBetweenParenAndAvailableAfterFunc() {
    let input = """
      func foo()

      @available(macOS 10.13, *)
      func bar()
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func noAddSpaceAroundTypedThrowsFunctionType() {
    let input = """
      func foo() throws (Bar) -> Baz {}
      """
    let output = """
      func foo() throws(Bar) -> Baz {}
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenParenAndBorrowing() {
    let input = """
      func foo(_: borrowing(any Foo)) {}
      """
    let output = """
      func foo(_: borrowing (any Foo)) {}
      """
    testFormatting(
      for: input, output, rule: .spaceAroundParens,
      exclude: [.noExplicitOwnership])
  }

  @Test func addSpaceBetweenParenAndIsolated() {
    let input = """
      func foo(isolation _: isolated(any Actor)) {}
      """
    let output = """
      func foo(isolation _: isolated (any Actor)) {}
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func addSpaceBetweenParenAndSending() {
    let input = """
      func foo(_: sending(any Foo)) {}
      """
    let output = """
      func foo(_: sending (any Foo)) {}
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func ofTupleSpacing() {
    let input = """
      let foo: [4 of(String, Int)]
      """
    let output = """
      let foo: [4 of (String, Int)]
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func ofIdentifierParenSpacing() {
    let input = """
      if foo.of(String.self) {}
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func asTupleCastingSpacing() {
    let input = """
      foo as(String, Int)
      """
    let output = """
      foo as (String, Int)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func asOptionalTupleCastingSpacing() {
    let input = """
      foo as? (String, Int)
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func isTupleTestingSpacing() {
    let input = """
      if foo is(String, Int) {}
      """
    let output = """
      if foo is (String, Int) {}
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }

  @Test func isIdentifierParenSpacing() {
    let input = """
      if foo.is(String.self, Int.self) {}
      """
    testFormatting(for: input, rule: .spaceAroundParens)
  }

  @Test func spaceBeforeTupleIndexCall() {
    let input = """
      foo.1 (2)
      """
    let output = """
      foo.1(2)
      """
    testFormatting(for: input, output, rule: .spaceAroundParens)
  }
}
