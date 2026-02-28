import Testing

@testable import Swiftiomatic

@Suite struct BracesTests {
  @Test func allmanBracesAreConverted() {
    let input = """
      func foo()
      {
          statement
      }
      """
    let output = """
      func foo() {
          statement
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func nestedAllmanBracesAreConverted() {
    let input = """
      func foo()
      {
          for bar in baz
          {
              print(bar)
          }
      }
      """
    let output = """
      func foo() {
          for bar in baz {
              print(bar)
          }
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func knRBracesAfterComment() {
    let input = """
      func foo() // comment
      {
          statement
      }
      """
    testFormatting(for: input, rule: .braces)
  }

  @Test func knRBracesAfterMultilineComment() {
    let input = """
      func foo() /* comment/ncomment */
      {
          statement
      }
      """
    testFormatting(for: input, rule: .braces)
  }

  @Test func knRBracesAfterMultilineComment2() {
    let input = """
      class Foo /*
       aaa
       */
      {
          // foo
      }
      """
    testFormatting(for: input, rule: .braces)
  }

  @Test func knRExtraSpaceNotAddedBeforeBrace() {
    let input = """
      foo({ bar })
      """
    testFormatting(for: input, rule: .braces, exclude: [.trailingClosures])
  }

  @Test func knRLinebreakNotRemovedBeforeInlineBlockNot() {
    let input = """
      func foo() -> Bool
      { return false }
      """
    testFormatting(for: input, rule: .braces, exclude: [.wrapFunctionBodies])
  }

  @Test func knRNoMangleCommentBeforeClosure() {
    let input = """
      [
          // foo
          foo,
          // bar
          {
              bar
          }(),
      ]
      """
    testFormatting(for: input, rule: .braces, exclude: [.redundantClosure])
  }

  @Test func knRNoMangleClosureReturningClosure() {
    let input = """
      foo { bar in
          {
              bar()
          }
      }
      """
    testFormatting(for: input, rule: .braces)
  }

  @Test func knRNoMangleClosureReturningClosure2() {
    let input = """
      foo {
          {
              bar()
          }
      }
      """
    testFormatting(for: input, rule: .braces)
  }

  @Test func allmanNoMangleClosureReturningClosure() {
    let input = """
      foo
      { bar in
          {
              bar()
          }
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, rule: .braces, options: options)
  }

  @Test func knRUnwrapClosure() {
    let input = """
      let foo =
      { bar in
          bar()
      }
      """
    let output = """
      let foo = { bar in
          bar()
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func knRNoUnwrapClosureIfWidthExceeded() {
    let input = """
      let foo =
      { bar in
          bar()
      }
      """
    let options = FormatOptions(maxWidth: 15)
    testFormatting(for: input, rule: .braces, options: options, exclude: [.indent])
  }

  @Test func knRClosingBraceWrapped() {
    let input = """
      func foo() {
          print(bar) }
      """
    let output = """
      func foo() {
          print(bar)
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func knRInlineBracesNotWrapped() {
    let input = """
      func foo() { print(bar) }
      """
    testFormatting(for: input, rule: .braces, exclude: [.wrapFunctionBodies])
  }

  @Test func allmanComputedPropertyBracesConverted() {
    let input = """
      var foo: Int
      {
          return 5
      }
      """
    let output = """
      var foo: Int {
          return 5
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func allmanInitBracesConverted() {
    let input = """
      init()
      {
          foo = 5
      }
      """
    let output = """
      init() {
          foo = 5
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func allmanSubscriptBracesConverted() {
    let input = """
      subscript(i: Int) -> Int
      {
          foo[i]
      }
      """
    let output = """
      subscript(i: Int) -> Int {
          foo[i]
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func bracesForStructDeclaration() {
    let input = """
      struct Foo
      {
          // foo
      }
      """
    let output = """
      struct Foo {
          // foo
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func bracesForInit() {
    let input = """
      init(foo: Int)
      {
          self.foo = foo
      }
      """
    let output = """
      init(foo: Int) {
          self.foo = foo
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func bracesForIfStatement() {
    let input = """
      if foo
      {
          // foo
      }
      """
    let output = """
      if foo {
          // foo
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func bracesForExtension() {
    let input = """
      extension Foo
      {
          // foo
      }
      """
    let output = """
      extension Foo {
          // foo
      }
      """
    testFormatting(for: input, output, rule: .braces, exclude: [.emptyExtensions])
  }

  @Test func bracesForOptionalInit() {
    let input = """
      init?()
      {
          return nil
      }
      """
    let output = """
      init?() {
          return nil
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  @Test func braceUnwrappedIfWrapMultilineStatementBracesRuleDisabled() {
    let input = """
      if let foo = bar,
         let baz = quux
      {
          return nil
      }
      """
    let output = """
      if let foo = bar,
         let baz = quux {
          return nil
      }
      """
    testFormatting(
      for: input, output, rule: .braces,
      exclude: [.wrapMultilineStatementBraces])
  }

  @Test func braceNotUnwrappedIfWrapMultilineStatementBracesRuleDisabled() {
    let input = """
      if let foo = bar,
         let baz = quux
      {
          return nil
      }
      """
    testFormatting(
      for: input,
      rules: [
        .braces, .wrapMultilineStatementBraces,
      ])
  }

  @Test func issue1534() {
    let input = """
      func application(_: UIApplication, willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
      {
      //
      }
      """
    let output = """
      func application(_: UIApplication, willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
      //
      }
      """
    testFormatting(for: input, output, rule: .braces)
  }

  // allman style

  @Test func knRBracesAreConverted() {
    let input = """
      func foo() {
          statement
      }
      """
    let output = """
      func foo()
      {
          statement
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBlankLineAfterBraceRemoved() {
    let input = """
      func foo() {

          statement
      }
      """
    let output = """
      func foo()
      {
          statement
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBraceInsideParensNotConverted() {
    let input = """
      foo({
          bar
      })
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(
      for: input, rule: .braces, options: options,
      exclude: [.trailingClosures])
  }

  @Test func allmanBraceDoClauseIndent() {
    let input = """
      do {
          foo
      }
      """
    let output = """
      do
      {
          foo
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBraceCatchClauseIndent() {
    let input = """
      do {
          try foo
      }
      catch {
      }
      """
    let output = """
      do
      {
          try foo
      }
      catch
      {
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(
      for: input, output, rule: .braces, options: options,
      exclude: [.emptyBraces])
  }

  @Test func allmanBraceDoThrowsCatchClauseIndent() {
    let input = """
      do throws(Foo) {
          try foo
      }
      catch {
      }
      """
    let output = """
      do throws(Foo)
      {
          try foo
      }
      catch
      {
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(
      for: input, output, rule: .braces, options: options,
      exclude: [.emptyBraces])
  }

  @Test func allmanBraceRepeatWhileIndent() {
    let input = """
      repeat {
          foo
      }
      while x
      """
    let output = """
      repeat
      {
          foo
      }
      while x
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBraceOptionalComputedPropertyIndent() {
    let input = """
      var foo: Int? {
          return 5
      }
      """
    let output = """
      var foo: Int?
      {
          return 5
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBraceThrowsFunctionIndent() {
    let input = """
      func foo() throws {
          bar
      }
      """
    let output = """
      func foo() throws
      {
          bar
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBraceAsyncFunctionIndent() {
    let input = """
      func foo() async {
          bar
      }
      """
    let output = """
      func foo() async
      {
          bar
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBraceAfterCommentIndent() {
    let input = """
      func foo() { // foo

          bar
      }
      """
    let output = """
      func foo()
      { // foo
          bar
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBraceAfterSwitch() {
    let input = """
      switch foo {
      case bar: break
      }
      """
    let output = """
      switch foo
      {
      case bar: break
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBracesForStructDeclaration() {
    let input = """
      struct Foo {
          // foo
      }
      """
    let output = """
      struct Foo
      {
          // foo
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(
      for: input, output,
      rule: .braces,
      options: options
    )
  }

  @Test func allmanBracesForInit() {
    let input = """
      init(foo: Int) {
          self.foo = foo
      }
      """
    let output = """
      init(foo: Int)
      {
          self.foo = foo
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBracesForOptionalInit() {
    let input = """
      init?() {
          return nil
      }
      """
    let output = """
      init?()
      {
          return nil
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBracesForIfStatement() {
    let input = """
      if foo {
          // foo
      }
      """
    let output = """
      if foo
      {
          // foo
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBracesForIfStatement2() {
    let input = """
      if foo > 0 {
          // foo
      }
      """
    let output = """
      if foo > 0
      {
          // foo
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options)
  }

  @Test func allmanBracesForExtension() {
    let input = """
      extension Foo {
          // foo
      }
      """
    let output = """
      extension Foo
      {
          // foo
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(for: input, output, rule: .braces, options: options, exclude: [.emptyExtensions])
  }

  @Test func emptyAllmanIfElseBraces() {
    let input = """
      if true {

      } else {

      }
      """
    let output = """
      if true
      {}
      else
      {}
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(
      for: input, [output],
      rules: [
        .braces, .emptyBraces, .elseOnSameLine,
      ], options: options)
  }

  @Test func trailingClosureWrappingAfterSingleParamMethodCall() {
    let input = """
      func build() -> StateStore {
          StateStore(initial: State(
              foo: foo,
              bar: bar))
          {
              ActionHandler()
          }
      }
      """

    let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
    testFormatting(for: input, rules: [.braces, .wrapMultilineStatementBraces], options: options)
  }

  @Test func trailingClosureWrappingAfterMethodWithPartialWrappingAndClosures() {
    let input = """
      Picker("Language", selection: .init(
          get: { self.store.state.language },
          set: { self.store.handle(.setLanguage($0)) }))
      {
          Text("English").tag(Language.english)
          Text("German").tag(Language.german)
      }
      """

    let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
    testFormatting(for: input, rules: [.braces, .wrapMultilineStatementBraces], options: options)
  }

  @Test func wrapInitBraceWithComplexWhereClause() {
    let input = """
      class Bar {
          init(
              foo: Foo
          ) where
              Foo: Fooable,
              Foo.Something == Something
          {
              self.foo = foo
          }
      }
      """
    testFormatting(for: input, rules: [.braces, .wrapMultilineStatementBraces])
  }
}
