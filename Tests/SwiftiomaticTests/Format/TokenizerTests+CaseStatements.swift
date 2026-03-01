import Testing

@testable import Swiftiomatic

extension TokenizerTests {
  // MARK: optionals

  @Test func assignOptional() {
    let input = "Int?=nil"
    let output: [Token] = [
      .identifier("Int"),
      .operator("?", .postfix),
      .operator("=", .infix),
      .identifier("nil"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func questionMarkEqualOperator() {
    let input = "foo ?= bar"
    let output: [Token] = [
      .identifier("foo"),
      .space(" "),
      .operator("?=", .infix),
      .space(" "),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func optionalChaining() {
    let input = "foo!.bar"
    let output: [Token] = [
      .identifier("foo"),
      .operator("!", .postfix),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func multipleOptionalChaining() {
    let input = "foo?!?.bar"
    let output: [Token] = [
      .identifier("foo"),
      .operator("?", .postfix),
      .operator("!", .postfix),
      .operator("?", .postfix),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func splitLineOptionalChaining() {
    let input = "foo?\n    .bar"
    let output: [Token] = [
      .identifier("foo"),
      .operator("?", .postfix),
      .lineBreak("\n", 1),
      .space("    "),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: case statements

  @Test func singleLineEnum() {
    let input = "enum Foo {case Bar, Baz}"
    let output: [Token] = [
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .space(" "),
      .startOfScope("{"),
      .keyword("case"),
      .space(" "),
      .identifier("Bar"),
      .delimiter(","),
      .space(" "),
      .identifier("Baz"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineGenericEnum() {
    let input = "enum Foo<T> {case Bar, Baz}"
    let output: [Token] = [
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .space(" "),
      .startOfScope("{"),
      .keyword("case"),
      .space(" "),
      .identifier("Bar"),
      .delimiter(","),
      .space(" "),
      .identifier("Baz"),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func multilineLineEnum() {
    let input = "enum Foo {\ncase Bar\ncase Baz\n}"
    let output: [Token] = [
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .keyword("case"),
      .space(" "),
      .identifier("Bar"),
      .lineBreak("\n", 2),
      .keyword("case"),
      .space(" "),
      .identifier("Baz"),
      .lineBreak("\n", 3),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchStatement() {
    let input = "switch x {\ncase 1:\nbreak\ncase 2:\nbreak\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("1", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("break"),
      .lineBreak("\n", 3),
      .endOfScope("case"),
      .space(" "),
      .number("2", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 6),
      .keyword("break"),
      .lineBreak("\n", 7),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchStatementWithEnumCases() {
    let input = "switch x {\ncase.foo,\n.bar:\nbreak\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .operator(".", .prefix),
      .identifier("foo"),
      .delimiter(","),
      .lineBreak("\n", 2),
      .operator(".", .prefix),
      .identifier("bar"),
      .startOfScope(":"),
      .lineBreak("\n", 3),
      .keyword("break"),
      .lineBreak("\n", 4),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 5),
      .keyword("break"),
      .lineBreak("\n", 6),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingDictionaryDefault() {
    let input = "switch x {\ncase y: foo[\"z\", default: []]\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .identifier("y"),
      .startOfScope(":"),
      .space(" "),
      .identifier("foo"),
      .startOfScope("["),
      .startOfScope("\""),
      .stringBody("z"),
      .endOfScope("\""),
      .delimiter(","),
      .space(" "),
      .identifier("default"),
      .delimiter(":"),
      .space(" "),
      .startOfScope("["),
      .endOfScope("]"),
      .endOfScope("]"),
      .lineBreak("\n", 2),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseIsDictionaryStatement() {
    let input = "switch x {\ncase foo is [Key: Value]:\nbreak\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .keyword("is"),
      .space(" "),
      .startOfScope("["),
      .identifier("Key"),
      .delimiter(":"),
      .space(" "),
      .identifier("Value"),
      .endOfScope("]"),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("break"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingCaseIdentifier() {
    let input = "switch x {\ncase 1:\nfoo.case\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("1", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .identifier("foo"),
      .operator(".", .infix),
      .identifier("case"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingDefaultIdentifier() {
    let input = "switch x {\ncase 1:\nfoo.default\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("1", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .identifier("foo"),
      .operator(".", .infix),
      .identifier("default"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingIfCase() {
    let input = "switch x {\ncase 1:\nif case x = y {}\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("1", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("if"),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("y"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingIfCaseCommaCase() {
    let input = "switch x {\ncase 1:\nif case w = x, case y = z {}\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("1", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("if"),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .identifier("w"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("x"),
      .delimiter(","),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .identifier("y"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("z"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingGuardCase() {
    let input = "switch x {\ncase 1:\nguard case x = y else {}\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("1", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("guard"),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("y"),
      .space(" "),
      .keyword("else"),
      .space(" "),
      .startOfScope("{"),
      .endOfScope("}"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchFollowedByEnum() {
    let input = "switch x {\ncase y: break\ndefault: break\n}\nenum Foo {\ncase z\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .identifier("y"),
      .startOfScope(":"),
      .space(" "),
      .keyword("break"),
      .lineBreak("\n", 2),
      .endOfScope("default"),
      .startOfScope(":"),
      .space(" "),
      .keyword("break"),
      .lineBreak("\n", 3),
      .endOfScope("}"),
      .lineBreak("\n", 4),
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 5),
      .keyword("case"),
      .space(" "),
      .identifier("z"),
      .lineBreak("\n", 6),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingSwitchIdentifierFollowedByEnum() {
    let input = "switch x {\ncase 1:\nfoo.switch\ndefault:\nbreak\n}\nenum Foo {\ncase z\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("1", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .identifier("foo"),
      .operator(".", .infix),
      .identifier("switch"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
      .lineBreak("\n", 6),
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 7),
      .keyword("case"),
      .space(" "),
      .identifier("z"),
      .lineBreak("\n", 8),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchCaseContainingRangeOperator() {
    let input = "switch x {\ncase 0 ..< 2:\nbreak\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .number("0", .integer),
      .space(" "),
      .operator("..<", .infix),
      .space(" "),
      .number("2", .integer),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("break"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func enumDeclarationInsideSwitchCase() {
    let input = "switch x {\ncase y:\nenum Foo {\ncase z\n}\nbreak\ndefault: break\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .identifier("y"),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 3),
      .keyword("case"),
      .space(" "),
      .identifier("z"),
      .lineBreak("\n", 4),
      .endOfScope("}"),
      .lineBreak("\n", 5),
      .keyword("break"),
      .lineBreak("\n", 6),
      .endOfScope("default"),
      .startOfScope(":"),
      .space(" "),
      .keyword("break"),
      .lineBreak("\n", 7),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func defaultAfterWhereCondition() {
    let input = "switch foo {\ncase _ where baz < quux:\nbreak\ndefault:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .identifier("_"),
      .space(" "),
      .keyword("where"),
      .space(" "),
      .identifier("baz"),
      .space(" "),
      .operator("<", .infix),
      .space(" "),
      .identifier("quux"),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("break"),
      .lineBreak("\n", 3),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 4),
      .keyword("break"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func enumWithConditionalCase() {
    let input = "enum Foo {\ncase bar\n#if baz\ncase baz\n#endif\n}"
    let output: [Token] = [
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .keyword("case"),
      .space(" "),
      .identifier("bar"),
      .lineBreak("\n", 2),
      .startOfScope("#if"),
      .space(" "),
      .identifier("baz"),
      .lineBreak("\n", 3),
      .keyword("case"),
      .space(" "),
      .identifier("baz"),
      .lineBreak("\n", 4),
      .endOfScope("#endif"),
      .lineBreak("\n", 5),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchWithConditionalCase() {
    let input = "switch foo {\ncase bar:\nbreak\n#if baz\ndefault:\nbreak\n#endif\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .endOfScope("case"),
      .space(" "),
      .identifier("bar"),
      .startOfScope(":"),
      .lineBreak("\n", 2),
      .keyword("break"),
      .lineBreak("\n", 3),
      .startOfScope("#if"),
      .space(" "),
      .identifier("baz"),
      .lineBreak("\n", 4),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 5),
      .keyword("break"),
      .lineBreak("\n", 6),
      .endOfScope("#endif"),
      .lineBreak("\n", 7),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchWithConditionalCase2() {
    let input = "switch foo {\n#if baz\ndefault:\nbreak\n#else\ncase bar:\nbreak\n#endif\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .startOfScope("#if"),
      .space(" "),
      .identifier("baz"),
      .lineBreak("\n", 2),
      .endOfScope("default"),
      .startOfScope(":"),
      .lineBreak("\n", 3),
      .keyword("break"),
      .lineBreak("\n", 4),
      .keyword("#else"),
      .lineBreak("\n", 5),
      .endOfScope("case"),
      .space(" "),
      .identifier("bar"),
      .startOfScope(":"),
      .lineBreak("\n", 6),
      .keyword("break"),
      .lineBreak("\n", 7),
      .endOfScope("#endif"),
      .lineBreak("\n", 8),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func switchWithConditionalCase3() {
    let input = "switch foo {\n#if baz\ncase foo:\nbreak\n#endif\ncase bar:\nbreak\n}"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .startOfScope("{"),
      .lineBreak("\n", 1),
      .startOfScope("#if"),
      .space(" "),
      .identifier("baz"),
      .lineBreak("\n", 2),
      .endOfScope("case"),
      .space(" "),
      .identifier("foo"),
      .startOfScope(":"),
      .lineBreak("\n", 3),
      .keyword("break"),
      .lineBreak("\n", 4),
      .endOfScope("#endif"),
      .lineBreak("\n", 5),
      .endOfScope("case"),
      .space(" "),
      .identifier("bar"),
      .startOfScope(":"),
      .lineBreak("\n", 6),
      .keyword("break"),
      .lineBreak("\n", 7),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func genericEnumCase() {
    let input = "enum Foo<T>: Bar where T: Bar { case bar }"
    let output: [Token] = [
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .startOfScope("<"),
      .identifier("T"),
      .endOfScope(">"),
      .delimiter(":"),
      .space(" "),
      .identifier("Bar"),
      .space(" "),
      .keyword("where"),
      .space(" "),
      .identifier("T"),
      .delimiter(":"),
      .space(" "),
      .identifier("Bar"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .identifier("bar"),
      .space(" "),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func caseEnumValueWithoutSpaces() {
    let input = "switch x { case.foo:break }"
    let output: [Token] = [
      .keyword("switch"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .endOfScope("case"),
      .operator(".", .prefix),
      .identifier("foo"),
      .startOfScope(":"),
      .keyword("break"),
      .space(" "),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func uncheckedSendableEnum() {
    let input = "enum Foo: @unchecked Sendable { case bar }"
    let output: [Token] = [
      .keyword("enum"),
      .space(" "),
      .identifier("Foo"),
      .delimiter(":"),
      .space(" "),
      .keyword("@unchecked"),
      .space(" "),
      .identifier("Sendable"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .identifier("bar"),
      .space(" "),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func forCaseLetPreceededByAwait() {
    let input =
      "func forGroup(_ group: TaskGroup<String?>) async { for await case let value? in group { print(value.description) } }"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("forGroup"),
      .startOfScope("("),
      .identifier("_"),
      .space(" "),
      .identifier("group"),
      .delimiter(":"),
      .space(" "),
      .identifier("TaskGroup"),
      .startOfScope("<"),
      .identifier("String"),
      .operator("?", .postfix),
      .endOfScope(">"),
      .endOfScope(")"),
      .space(" "),
      .identifier("async"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .keyword("for"),
      .space(" "),
      .keyword("await"),
      .space(" "),
      .keyword("case"),
      .space(" "),
      .keyword("let"),
      .space(" "),
      .identifier("value"),
      .operator("?", .postfix),
      .space(" "),
      .keyword("in"),
      .space(" "),
      .identifier("group"),
      .space(" "),
      .startOfScope("{"),
      .space(" "),
      .identifier("print"),
      .startOfScope("("),
      .identifier("value"),
      .operator(".", .infix),
      .identifier("description"),
      .endOfScope(")"),
      .space(" "),
      .endOfScope("}"),
      .space(" "),
      .endOfScope("}"),
    ]
    #expect(tokenize(input) == output)
  }

}
