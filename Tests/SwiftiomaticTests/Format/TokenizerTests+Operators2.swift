import Testing

@testable import Swiftiomatic

extension TokenizerTests {
  @Test func genericDeclarationWithoutSpace() {
    let input = "let foo: Foo<String,Int>=[]"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .delimiter(":"),
      .space(" "),
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("String"),
      .delimiter(","),
      .identifier("Int"),
      .endOfScope(">"),
      .operator("=", .infix),
      .startOfScope("["),
      .endOfScope("]"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericClassInitThatLooksLikeTuple() {
    let input = "(Foo<String,Int>(Bar))"
    let output: [Token] = [
      .startOfScope("("),
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("String"),
      .delimiter(","),
      .identifier("Int"),
      .endOfScope(">"),
      .startOfScope("("),
      .identifier("Bar"),
      .endOfScope(")"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func customChevronOperatorThatLooksLikeGeneric() {
    let input = "Foo<Bar,Baz>>>5"
    let output: [Token] = [
      .identifier("Foo"),
      .operator("<", .infix),
      .identifier("Bar"),
      .delimiter(","),
      .identifier("Baz"),
      .operator(">>>", .infix),
      .number("5", .integer),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func chevronOperatorDoesNotBreakScopeStack() {
    let input = "if a << b != 0 { let foo = bar() }"
    let output: [Token] = [
      .keyword("if"),
      .space(" "),
      .identifier("a"),
      .space(" "),
      .operator("<<", .infix),
      .space(" "),
      .identifier("b"),
      .space(" "),
      .operator("!=", .infix),
      .space(" "),
      .number("0", .integer),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("bar"),
      .startOfScope("("),
      .endOfScope(")"),
      .space(" "),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericAsFunctionType() {
    let input = "Foo<Bar,Baz>->Void"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("Bar"),
      .delimiter(","),
      .identifier("Baz"),
      .endOfScope(">"),
      .operator("->", .infix),
      .identifier("Void"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericContainingFunctionType() {
    let input = "Foo<(Bar)->Baz>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .startOfScope("("),
      .identifier("Bar"),
      .endOfScope(")"),
      .operator("->", .infix),
      .identifier("Baz"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericContainingFunctionTypeWithMultipleArguments() {
    let input = "Foo<(Bar,Baz)->Quux>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .startOfScope("("),
      .identifier("Bar"),
      .delimiter(","),
      .identifier("Baz"),
      .endOfScope(")"),
      .operator("->", .infix),
      .identifier("Quux"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericContainingMultipleFunctionTypes() {
    let input = "Foo<(Bar)->Void,(Baz)->Void>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .startOfScope("("),
      .identifier("Bar"),
      .endOfScope(")"),
      .operator("->", .infix),
      .identifier("Void"),
      .delimiter(","),
      .startOfScope("("),
      .identifier("Baz"),
      .endOfScope(")"),
      .operator("->", .infix),
      .identifier("Void"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericContainingArrayType() {
    let input = "Foo<[Bar],Baz>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .startOfScope("["),
      .identifier("Bar"),
      .endOfScope("]"),
      .delimiter(","),
      .identifier("Baz"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericContainingTupleType() {
    let input = "Foo<(Bar,Baz)>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .startOfScope("("),
      .identifier("Bar"),
      .delimiter(","),
      .identifier("Baz"),
      .endOfScope(")"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericContainingArrayAndTupleType() {
    let input = "Foo<[Bar],(Baz)>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .startOfScope("["),
      .identifier("Bar"),
      .endOfScope("]"),
      .delimiter(","),
      .startOfScope("("),
      .identifier("Baz"),
      .endOfScope(")"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericFollowedByIn() {
    let input = "Foo<Bar,Baz> in"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("Bar"),
      .delimiter(","),
      .identifier("Baz"),
      .endOfScope(">"),
      .space(" "),
      .keyword("in"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func optionalGenericType() {
    let input = "Foo<T?,U>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("T"),
      .operator("?", .postfix),
      .delimiter(","),
      .identifier("U"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func trailingOptionalGenericType() {
    let input = "Foo<T?>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("T"),
      .operator("?", .postfix),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func nestedOptionalGenericType() {
    let input = "Foo<Bar<T?>>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("Bar"),
      .startOfScope("<"),
      .identifier("T"),
      .operator("?", .postfix),
      .endOfScope(">"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func deeplyNestedGenericType() {
    let input = "Foo<Bar<Baz<Quux>>>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("Bar"),
      .startOfScope("<"),
      .identifier("Baz"),
      .startOfScope("<"),
      .identifier("Quux"),
      .endOfScope(">"),
      .endOfScope(">"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericFollowedByGreaterThan() {
    let input = "Foo<T>\na=b>c"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .lineBreak("\n", 1),
      .identifier("a"),
      .operator("=", .infix),
      .identifier("b"),
      .operator(">", .infix),
      .identifier("c"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericFollowedByElipsis() {
    let input = "foo<T>(bar: Baz<T>...)"
    let output: [Token] = [
      .identifier("foo"),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .startOfScope("("),
      .identifier("bar"),
      .delimiter(":"),
      .space(" "),
      .identifier("Baz"),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .operator("...", .postfix),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericOperatorFunction() {
    let input = "func ==<T>()"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .operator("==", .none),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .startOfScope("("),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericCustomOperatorFunction() {
    let input = "func ∘<T,U>()"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .operator("∘", .none),
      .startOfScope("<"),
      .identifier("T"),
      .delimiter(","),
      .identifier("U"),
      .endOfScope(">"),
      .startOfScope("("),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericTypeContainingAmpersand() {
    let input = "Foo<Bar: Baz & Quux>"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("Bar"),
      .delimiter(":"),
      .space(" "),
      .identifier("Baz"),
      .space(" "),
      .operator("&", .infix),
      .space(" "),
      .identifier("Quux"),
      .endOfScope(">"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericTypeFollowedByAndOperator() {
    let input = "Foo<Bar> && baz"
    let output: [Token] = [
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("Bar"),
      .endOfScope(">"),
      .space(" "),
      .operator("&&", .infix),
      .space(" "),
      .identifier("baz"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func customOperatorStartingWithOpenChevron() {
    let input = "foo<--bar"
    let output: [Token] = [
      .identifier("foo"),
      .operator("<--", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func customOperatorEndingWithCloseChevron() {
    let input = "foo-->bar"
    let output: [Token] = [
      .identifier("foo"),
      .operator("-->", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func greaterThanLessThanOperator() {
    let input = "foo><bar"
    let output: [Token] = [
      .identifier("foo"),
      .operator("><", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func lessThanGreaterThanOperator() {
    let input = "foo<>bar"
    let output: [Token] = [
      .identifier("foo"),
      .operator("<>", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericFollowedByAssign() {
    let input = "let foo: Bar<Baz> = 5"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .delimiter(":"),
      .space(" "),
      .identifier("Bar"),
      .startOfScope("<"),
      .identifier("Baz"),
      .endOfScope(">"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .number("5", .integer),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericInFailableInit() {
    let input = "init?<T>()"
    let output: [Token] = [
      .keyword("init"),
      .operator("?", .postfix),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .startOfScope("("),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func infixEqualsOperatorWithSpace() {
    let input = "operator == {}"
    let output: [Token] = [
      .keyword("operator"),
      .space(" "),
      .operator("==", .none),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func infixEqualsOperatorWithoutSpace() {
    let input = "operator =={}"
    let output: [Token] = [
      .keyword("operator"),
      .space(" "),
      .operator("==", .none),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func infixQuestionMarkChevronOperatorWithSpace() {
    let input = "operator ?< {}"
    let output: [Token] = [
      .keyword("operator"),
      .space(" "),
      .operator("?<", .none),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func infixQuestionMarkChevronOperatorWithoutSpace() {
    let input = "operator ?<{}"
    let output: [Token] = [
      .keyword("operator"),
      .space(" "),
      .operator("?<", .none),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func infixEqualsDoubleChevronOperator() {
    let input = "infix operator =<<"
    let output: [Token] = [
      .identifier("infix"),
      .space(" "),
      .keyword("operator"),
      .space(" "),
      .operator("=<<", .none),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func infixEqualsDoubleChevronGenericFunction() {
    let input = "func =<<<T>()"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .operator("=<<", .none),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .startOfScope("("),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func halfOpenRangeFollowedByComment() {
    let input = "1..<5\n//comment"
    let output: [Token] = [
      .number("1", .integer),
      .operator("..<", .infix),
      .number("5", .integer),
      .lineBreak("\n", 1),
      .startOfScope("//"),
      .commentBody("comment"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func sortAscending() {
    let input = "sort(by: <)"
    let output: [Token] = [
      .identifier("sort"),
      .startOfScope("("),
      .identifier("by"),
      .delimiter(":"),
      .space(" "),
      .operator("<", .none),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func sortDescending() {
    let input = "sort(by: >)"
    let output: [Token] = [
      .identifier("sort"),
      .startOfScope("("),
      .identifier("by"),
      .delimiter(":"),
      .space(" "),
      .operator(">", .none),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func ifLessThanGreaterThanExpression() {
    let input = "if x < (y + z), y > (z * w) {}"
    let output: [Token] = [
      .keyword("if"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .operator("<", .infix),
      .space(" "),
      .startOfScope("("),
      .identifier("y"),
      .space(" "),
      .operator("+", .infix),
      .space(" "),
      .identifier("z"),
      .endOfScope(")"),
      .delimiter(","),
      .space(" "),
      .identifier("y"),
      .space(" "),
      .operator(">", .infix),
      .space(" "),
      .startOfScope("("),
      .identifier("z"),
      .space(" "),
      .operator("*", .infix),
      .space(" "),
      .identifier("w"),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func ifLessThanIfGreaterThan() {
    let input = "if x < 0 {}\nif y > (0) {}"
    let output: [Token] = [
      .keyword("if"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .operator("<", .infix),
      .space(" "),
      .number("0", .integer),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
      .lineBreak("\n", 1),
      .keyword("if"),
      .space(" "),
      .identifier("y"),
      .space(" "),
      .operator(">", .infix),
      .space(" "),
      .startOfScope("("),
      .number("0", .integer),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func lessThanEnumCase() {
    let input = "XCTAssertFalse(.never < .never)"
    let output: [Token] = [
      .identifier("XCTAssertFalse"),
      .startOfScope("("),
      .operator(".", .prefix),
      .identifier("never"),
      .space(" "),
      .operator("<", .infix),
      .space(" "),
      .operator(".", .prefix),
      .identifier("never"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func lessThanGreaterThanEnumCase() {
    let input = "if foo < .bar, baz > .quux"
    let output: [Token] = [
      .keyword("if"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("<", .infix),
      .space(" "),
      .operator(".", .prefix),
      .identifier("bar"),
      .delimiter(","),
      .space(" "),
      .identifier("baz"),
      .space(" "),
      .operator(">", .infix),
      .space(" "),
      .operator(".", .prefix),
      .identifier("quux"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericResultBuilder() {
    let input = "func foo(@SomeResultBuilder<Self> builder: () -> Void) {}"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("foo"),
      .startOfScope("("),
      .keyword("@SomeResultBuilder"),
      .startOfScope("<"),
      .identifier("Self"),
      .endOfScope(">"),
      .space(" "),
      .identifier("builder"),
      .delimiter(":"),
      .space(" "),
      .startOfScope("("),
      .endOfScope(")"),
      .space(" "),
      .operator("->", .infix),
      .space(" "),
      .identifier("Void"),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericResultBuilder2() {
    let input = "func foo(@SomeResultBuilder<Store<MainState>> builder: () -> Void) {}"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("foo"),
      .startOfScope("("),
      .keyword("@SomeResultBuilder"),
      .startOfScope("<"),
      .identifier("Store"),
      .startOfScope("<"),
      .identifier("MainState"),
      .endOfScope(">"),
      .endOfScope(">"),
      .space(" "),
      .identifier("builder"),
      .delimiter(":"),
      .space(" "),
      .startOfScope("("),
      .endOfScope(")"),
      .space(" "),
      .operator("->", .infix),
      .space(" "),
      .identifier("Void"),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericThrowingClosure() {
    let input = "let a = Thing<[(Int) throws -> [Int]]>([])"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("a"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("Thing"),
      .startOfScope("<"),
      .startOfScope("["),
      .startOfScope("("),
      .identifier("Int"),
      .endOfScope(")"),
      .space(" "),
      .keyword("throws"),
      .space(" "),
      .operator("->", .infix),
      .space(" "),
      .startOfScope("["),
      .identifier("Int"),
      .endOfScope("]"),
      .endOfScope("]"),
      .endOfScope(">"),
      .startOfScope("("),
      .startOfScope("["),
      .endOfScope("]"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

}
