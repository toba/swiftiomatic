import Testing

@testable import Swiftiomatic

extension TokenizerTests {
  // MARK: dot prefix

  @Test func enumValueInDictionaryLiteral() {
    let input = "[.foo:.bar]"
    let output: [Token] = [
      .startOfScope("["),
      .operator(".", .prefix),
      .identifier("foo"),
      .delimiter(":"),
      .operator(".", .prefix),
      .identifier("bar"),
      .endOfScope("]"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func ifdefPrefixDot() {
    let input = """
      foo
      #if bar
      .bar
      #else
      .baz
      #endif
      .quux
      """
    let output: [Token] = [
      .identifier("foo"),
      .lineBreak("\n", 1),
      .startOfScope("#if"),
      .space(" "),
      .identifier("bar"),
      .lineBreak("\n", 2),
      .operator(".", .infix),
      .identifier("bar"),
      .lineBreak("\n", 3),
      .keyword("#else"),
      .lineBreak("\n", 4),
      .operator(".", .infix),
      .identifier("baz"),
      .lineBreak("\n", 5),
      .endOfScope("#endif"),
      .lineBreak("\n", 6),
      .operator(".", .infix),
      .identifier("quux"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: linebreaks

  @Test func lF() {
    let input = "foo\nbar"
    let output: [Token] = [
      .identifier("foo"),
      .lineBreak("\n", 1),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func cR() {
    let input = "foo\rbar"
    let output: [Token] = [
      .identifier("foo"),
      .lineBreak("\r", 1),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func cRLF() {
    let input = "foo\r\nbar"
    let output: [Token] = [
      .identifier("foo"),
      .lineBreak("\r\n", 1),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func cRLFAfterComment() {
    let input = "//foo\r\n//bar"
    let output: [Token] = [
      .startOfScope("//"),
      .commentBody("foo"),
      .lineBreak("\r\n", 1),
      .startOfScope("//"),
      .commentBody("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func cRLFInMultilineComment() {
    let input = "/*foo\r\nbar*/"
    let output: [Token] = [
      .startOfScope("/*"),
      .commentBody("foo"),
      .lineBreak("\r\n", 1),
      .commentBody("bar"),
      .endOfScope("*/"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: keypaths

  @Test func namespacedKeyPath() {
    let input = "let foo = \\Foo.bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("\\", .prefix),
      .identifier("Foo"),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anonymousKeyPath() {
    let input = "let foo = \\.bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("\\", .prefix),
      .operator(".", .prefix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anonymousSubscriptKeyPath() {
    let input = "let foo = \\.[0].bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("\\", .prefix),
      .operator(".", .prefix),
      .startOfScope("["),
      .number("0", .integer),
      .endOfScope("]"),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anonymousOptionalKeyPath() {
    let input = "let foo = \\.?.bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("\\", .prefix),
      .operator(".", .prefix),
      .operator("?", .postfix),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anonymousOptionalSubscriptKeyPath() {
    let input = "let foo = \\.?[0].bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("\\", .prefix),
      .operator(".", .prefix),
      .operator("?", .postfix),
      .startOfScope("["),
      .number("0", .integer),
      .endOfScope("]"),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func attributeInsideGenericArguments() {
    let input = "Foo<(@MainActor () -> Void)?>(nil)"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .startOfScope("("),
      .keyword("@MainActor"),
      .space(" "),
      .startOfScope("("),
      .endOfScope(")"),
      .space(" "),
      .operator("->", .infix),
      .space(" "),
      .identifier("Void"),
      .endOfScope(")"),
      .operator("?", .postfix),
      .endOfScope(">"),
      .startOfScope("("),
      .identifier("nil"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: Suppressed Conformances

  @Test func noncopyableStructDeclaration() {
    let input = "struct Foo: ~Copyable {}"
    let output: [Token] = [
      .keyword("struct"),
      .space(" "),
      .identifier("Foo"),
      .delimiter(":"),
      .space(" "),
      .operator("~", .prefix),
      .identifier("Copyable"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func suppressedConformanceInWhereCondition() {
    let input = "Foo<T> where T: ~Copyable"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .space(" "),
      .keyword("where"),
      .space(" "),
      .identifier("T"),
      .delimiter(":"),
      .space(" "),
      .operator("~", .prefix),
      .identifier("Copyable"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func suppressedConformancesOnGenericParameters() {
    let input = "Foo<T: ~Copyable, U: Sendable & ~Escapable>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("T"),
      .delimiter(":"),
      .space(" "),
      .operator("~", .prefix),
      .identifier("Copyable"),
      .delimiter(","),
      .space(" "),
      .identifier("U"),
      .delimiter(":"),
      .space(" "),
      .identifier("Sendable"),
      .space(" "),
      .operator("&", .infix),
      .space(" "),
      .operator("~", .prefix),
      .identifier("Escapable"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: borrowing and consuming modifiers

  @Test func borrowingParameterModifier() {
    let input = "func foo(_: borrowing Foo)"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("foo"),
      .startOfScope("("),
      .identifier("_"),
      .delimiter(":"),
      .space(" "),
      .identifier("borrowing"),
      .space(" "),
      .identifier("Foo"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func consumingParameterModifier() {
    let input = "func foo(_: consuming Foo)"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("foo"),
      .startOfScope("("),
      .identifier("_"),
      .delimiter(":"),
      .space(" "),
      .identifier("consuming"),
      .space(" "),
      .identifier("Foo"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func borrowingClosureParameter() {
    let input = "bar { (a: borrowing Foo) in a }"
    let output: [Token] = [
      .identifier("bar"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .startOfScope("("),
      .identifier("a"),
      .delimiter(":"),
      .space(" "),
      .identifier("borrowing"),
      .space(" "),
      .identifier("Foo"),
      .endOfScope(")"),
      .space(" "),
      .keyword("in"),
      .space(" "),
      .identifier("a"),
      .space(" "),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func borrowingFunctionSignature() {
    let input = "(borrowing Foo) -> Void"
    let output: [Token] = [
      .startOfScope("("),
      .identifier("borrowing"),
      .space(" "),
      .identifier("Foo"),
      .endOfScope(")"),
      .space(" "),
      .operator("->", .infix),
      .space(" "),
      .identifier("Void"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: consume and discard operators

  @Test func consumeOperator() {
    let input = "_ = consume x"
    let output: [Token] = [
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .keyword("consume"),
      .space(" "),
      .identifier("x"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func discardOperator() {
    let input = "discard x"
    let output: [Token] = [
      .keyword("discard"),
      .space(" "),
      .identifier("x"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func consumeFunction() {
    let input = "_ = consume (x)"
    let output: [Token] = [
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("consume"),
      .space(" "),
      .startOfScope("("),
      .identifier("x"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func consumeLabel() {
    let input = "func foo(consume bar: Int)"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("foo"),
      .startOfScope("("),
      .identifier("consume"),
      .space(" "),
      .identifier("bar"),
      .delimiter(":"),
      .space(" "),
      .identifier("Int"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func consumeVariable() {
    let input = "let consume = 5"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("consume"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .number("5", .integer),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: await

  @Test func awaitExpression() {
    let input = "let foo = await bar()"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .keyword("await"),
      .space(" "),
      .identifier("bar"),
      .startOfScope("("),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func awaitFunction() {
    let input = "func await()"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("await"),
      .startOfScope("("),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func awaitClass() {
    let input = "class await {}"
    let output: [Token] = [
      .keyword("class"),
      .space(" "),
      .identifier("await"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func awaitProperty() {
    let input = "let await = 5"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("await"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .number("5", .integer),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: actors

  @Test func actorType() {
    let input = "actor Foo {}"
    let output: [Token] = [
      .keyword("actor"),
      .space(" "),
      .identifier("Foo"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func actorProperty() {
    let input = "let actor = {}"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("actor"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func actorProperty2() {
    let input = "actor = 5"
    let output: [Token] = [
      .identifier("actor"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .number("5", .integer),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func actorProperty3() {
    let input = """
      self.actor = actor
      self.bar = bar
      """
    let output: [Token] = [
      .identifier("self"),
      .operator(".", .infix),
      .identifier("actor"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("actor"),
      .lineBreak("\n", 1),
      .identifier("self"),
      .operator(".", .infix),
      .identifier("bar"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func actorLabel() {
    let input = "init(actor: Actor) {}"
    let output: [Token] = [
      .keyword("init"),
      .startOfScope("("),
      .identifier("actor"),
      .delimiter(":"),
      .space(" "),
      .identifier("Actor"),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func actorVariable() {
    let input = "let foo = actor\nlet bar = foo"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("actor"),
      .lineBreak("\n", 1),
      .keyword("let"),
      .space(" "),
      .identifier("bar"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("foo"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: macros

  @Test func macroType() {
    let input = "macro stringify()"
    let output: [Token] = [
      .keyword("macro"),
      .space(" "),
      .identifier("stringify"),
      .startOfScope("("),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func macroProperty() {
    let input = "let macro = {}"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("macro"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: some / any

  @Test func someView() {
    let input = "var body: some View {}"
    let output: [Token] = [
      .keyword("var"),
      .space(" "),
      .identifier("body"),
      .delimiter(":"),
      .space(" "),
      .identifier("some"),
      .space(" "),
      .identifier("View"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anyView() {
    let input = "var body: any View {}"
    let output: [Token] = [
      .keyword("var"),
      .space(" "),
      .identifier("body"),
      .delimiter(":"),
      .space(" "),
      .identifier("any"),
      .space(" "),
      .identifier("View"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func someAnimal() {
    let input = "func feed(_ animal: some Animal) {}"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("feed"),
      .startOfScope("("),
      .identifier("_"),
      .space(" "),
      .identifier("animal"),
      .delimiter(":"),
      .space(" "),
      .identifier("some"),
      .space(" "),
      .identifier("Animal"),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anyAnimal() {
    let input = "func feed(_ animal: any Animal) {}"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("feed"),
      .startOfScope("("),
      .identifier("_"),
      .space(" "),
      .identifier("animal"),
      .delimiter(":"),
      .space(" "),
      .identifier("any"),
      .space(" "),
      .identifier("Animal"),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anyAnimalArray() {
    let input = "let animals: [any Animal]"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("animals"),
      .delimiter(":"),
      .space(" "),
      .startOfScope("["),
      .identifier("any"),
      .space(" "),
      .identifier("Animal"),
      .endOfScope("]"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func rawIdentifiers() {
    let input = """
      func `square returns x * x`() -> Int { 42 }
      enum ColorVariant { case `50`, `100`, `200` }
      let `1.circle` = "SF Symbol"
      struct `class` { let `for` = true }
      """
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("`square returns x * x`"),
      .startOfScope("("),
      .endOfScope(")"),
      .space(" "),
      .operator("->", .infix),
      .space(" "),
      .identifier("Int"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .number("42", .integer),
      .space(" "),
      .endOfScope("}"),
      .lineBreak("\n", 1),
      .keyword("enum"),
      .space(" "),
      .identifier("ColorVariant"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .identifier("`50`"),
      .delimiter(","),
      .space(" "),
      .identifier("`100`"),
      .delimiter(","),
      .space(" "),
      .identifier("`200`"),
      .space(" "),
      .endOfScope("}"),
      .lineBreak("\n", 2),
      .keyword("let"),
      .space(" "),
      .identifier("`1.circle`"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("\""),
      .stringBody("SF Symbol"),
      .endOfScope("\""),
      .lineBreak("\n", 3),
      .keyword("struct"),
      .space(" "),
      .identifier("`class`"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .keyword("let"),
      .space(" "),
      .identifier("`for`"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("true"),
      .space(" "),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }
}
