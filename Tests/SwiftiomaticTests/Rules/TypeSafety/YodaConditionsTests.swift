import Testing

@testable import Swiftiomatic

@Suite struct YodaConditionsTests {
  static let cases: [FormatCase] = [
    // Literal swaps
    FormatCase(
      "numericLiteralEqual",
      input: "5 == foo",
      output: "foo == 5"),
    FormatCase(
      "numericLiteralGreater",
      input: "5.1 > foo",
      output: "foo < 5.1"),
    FormatCase(
      "stringLiteralNotEqual",
      input: "\"foo\" != foo",
      output: "foo != \"foo\""),
    FormatCase(
      "nilNotEqual",
      input: "nil != foo",
      output: "foo != nil"),
    FormatCase(
      "trueNotEqual",
      input: "true != foo",
      output: "foo != true"),
    FormatCase(
      "enumCaseNotEqual",
      input: ".foo != foo",
      output: "foo != .foo"),
    FormatCase(
      "arrayLiteralNotEqual",
      input: "[5, 6] != foo",
      output: "foo != [5, 6]"),
    FormatCase(
      "nestedArrayLiteralNotEqual",
      input: "[5, [6, 7]] != foo",
      output: "foo != [5, [6, 7]]"),
    FormatCase(
      "dictionaryLiteralNotEqual",
      input: "[foo: 5, bar: 6] != foo",
      output: "foo != [foo: 5, bar: 6]"),

    // Subscript not treated as yoda
    FormatCase(
      "subscriptNotTreated",
      input: "foo[5] != bar"),
    FormatCase(
      "subscriptOfParenthesizedExpressionNotTreated",
      input: "(foo + bar)[5] != baz"),
    FormatCase(
      "subscriptOfUnwrappedValueNotTreated",
      input: "foo![5] != bar"),
    FormatCase(
      "subscriptOfExpressionWithInlineCommentNotTreated",
      input: "foo /* foo */ [5] != bar"),
    FormatCase(
      "subscriptOfCollectionNotTreated",
      input: "[foo][5] != bar"),
    FormatCase(
      "subscriptOfTrailingClosureNotTreated",
      input: "foo { [5] }[0] != bar"),

    FormatCase(
      "subscriptOfRhsNotMangled",
      input: "[1] == foo[0]",
      output: "foo[0] == [1]"),

    // Tuples
    FormatCase(
      "tuple",
      input: "(5, 6) != bar",
      output: "bar != (5, 6)"),
    FormatCase(
      "labeledTuple",
      input: "(foo: 5, bar: 6) != baz",
      output: "baz != (foo: 5, bar: 6)"),
    FormatCase(
      "nestedTuple",
      input: "(5, (6, 7)) != baz",
      output: "baz != (5, (6, 7))"),

    // Function call not treated as yoda
    FormatCase(
      "functionCallNotTreated",
      input: "foo(5) != bar"),
    FormatCase(
      "callOfParenthesizedExpressionNotTreated",
      input: "(foo + bar)(5) != baz"),
    FormatCase(
      "callOfUnwrappedValueNotTreated",
      input: "foo!(5) != bar"),
    FormatCase(
      "callOfExpressionWithInlineCommentNotTreated",
      input: "foo /* foo */ (5) != bar"),

    FormatCase(
      "callOfRhsNotMangled",
      input: "(1, 2) == foo(0)",
      output: "foo(0) == (1, 2)"),
    FormatCase(
      "trailingClosureOnRhsNotMangled",
      input: "(1, 2) == foo { $0 }",
      output: "foo { $0 } == (1, 2)"),

    // In statements
    FormatCase(
      "inIfStatement",
      input: "if 5 != foo {}",
      output: "if foo != 5 {}"),
    FormatCase(
      "inSecondClauseOfIfStatement",
      input: "if foo, 5 != bar {}",
      output: "if foo, bar != 5 {}"),

    // In expressions
    FormatCase(
      "inExpression",
      input: """
        let foo = 5 < bar
        baz()
        """,
      output: """
        let foo = bar > 5
        baz()
        """),
    FormatCase(
      "inExpressionWithTrailingClosure",
      input: "let foo = 5 < bar { baz() }",
      output: "let foo = bar { baz() } > 5"),
    FormatCase(
      "inFunctionCall",
      input: "foo(5 < bar)",
      output: "foo(bar > 5)"),
    FormatCase(
      "followedByExpression",
      input: "5 == foo + 6",
      output: "foo + 6 == 5"),

    // Prefix/postfix expressions
    FormatCase(
      "prefixExpression",
      input: "!false == foo",
      output: "foo == !false"),
    FormatCase(
      "prefixExpression2",
      input: "true == !foo",
      output: "!foo == true"),
    FormatCase(
      "postfixExpression",
      input: "5<*> == foo",
      output: "foo == 5<*>"),
    FormatCase(
      "doublePostfixExpression",
      input: "5!! == foo",
      output: "foo == 5!!"),

    FormatCase(
      "postfixExpressionNonYoda",
      input: "5 == 5<*>"),
    FormatCase(
      "postfixExpressionNonYoda2",
      input: "5<*> == 5"),
    FormatCase(
      "stringEqualsStringNonYoda",
      input: "\"foo\" == \"bar\""),
    FormatCase(
      "constantAfterNullCoalescingNonYoda",
      input: "foo.last ?? -1 < bar"),

    // Compound expressions
    FormatCase(
      "noMangleFollowedByAnd",
      input: "5 <= foo && foo <= 7",
      output: "foo >= 5 && foo <= 7"),
    FormatCase(
      "noMangleFollowedByOr",
      input: "5 <= foo || foo <= 7",
      output: "foo >= 5 || foo <= 7"),
    FormatCase(
      "noMangleFollowedByParentheses",
      input: "0 <= (foo + bar)",
      output: "(foo + bar) >= 0"),

    // Ternary
    FormatCase(
      "noMangleInTernary",
      input: "let z = 0 < y ? 3 : 4",
      output: "let z = y > 0 ? 3 : 4"),
    FormatCase(
      "noMangleInTernary2",
      input: "let z = y > 0 ? 0 < x : 4",
      output: "let z = y > 0 ? x > 0 : 4"),
    FormatCase(
      "noMangleInTernary3",
      input: "let z = y > 0 ? 3 : 0 < x",
      output: "let z = y > 0 ? 3 : x > 0"),

    // Edge cases
    FormatCase(
      "keyPathNotMangled",
      input: "\\.foo == bar"),
    FormatCase(
      "enumCaseLessThanEnumCase",
      input: "#expect(!(.never < .never))"),
    FormatCase(
      "genericFunctionsInEqualityExpressions",
      input: """
        print(method<Int>() == 123)
        print(method<Int>() == intVariable)
        print(method<Int>() == IntEnum.foo.rawValue)
        print(method<String>() == "string")
        print(method<String>() == stringVariable)
        print(method<String>() == StringEnum.foo.rawValue)
        """),
  ]

  @Test(arguments: Self.cases)
  func yodaConditions(_ c: FormatCase) {
    testFormatting(for: c.input, c.output, rule: .yodaConditions)
  }

  // MARK: - Special cases

  @Test func subscriptYodaConditionInIfStatementWithBraceOnNextLine() {
    let input = """
      if [0] == foo.bar[0]
      { baz() }
      """
    let output = """
      if foo.bar[0] == [0]
      { baz() }
      """
    testFormatting(
      for: input, output, rule: .yodaConditions,
      exclude: [.wrapConditionalBodies],
    )
  }

  // yodaSwap = literalsOnly

  @Test func noSwapYodaDotMember() {
    let input = """
      foo(where: .bar == baz)
      """
    let options = FormatOptions(yodaSwap: .literalsOnly)
    testFormatting(for: input, rule: .yodaConditions, options: options)
  }
}
