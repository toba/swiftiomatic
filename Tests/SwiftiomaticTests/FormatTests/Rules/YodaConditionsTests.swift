import Testing

@testable import Swiftiomatic

@Suite struct YodaConditionsTests {
  @Test func numericLiteralEqualYodaCondition() {
    let input = """
      5 == foo
      """
    let output = """
      foo == 5
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func numericLiteralGreaterYodaCondition() {
    let input = """
      5.1 > foo
      """
    let output = """
      foo < 5.1
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func stringLiteralNotEqualYodaCondition() {
    let input = """
      \"foo\" != foo
      """
    let output = """
      foo != \"foo\"
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func nilNotEqualYodaCondition() {
    let input = """
      nil != foo
      """
    let output = """
      foo != nil
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func trueNotEqualYodaCondition() {
    let input = """
      true != foo
      """
    let output = """
      foo != true
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func enumCaseNotEqualYodaCondition() {
    let input = """
      .foo != foo
      """
    let output = """
      foo != .foo
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func arrayLiteralNotEqualYodaCondition() {
    let input = """
      [5, 6] != foo
      """
    let output = """
      foo != [5, 6]
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func nestedArrayLiteralNotEqualYodaCondition() {
    let input = """
      [5, [6, 7]] != foo
      """
    let output = """
      foo != [5, [6, 7]]
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func dictionaryLiteralNotEqualYodaCondition() {
    let input = """
      [foo: 5, bar: 6] != foo
      """
    let output = """
      foo != [foo: 5, bar: 6]
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func subscriptNotTreatedAsYodaCondition() {
    let input = """
      foo[5] != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func subscriptOfParenthesizedExpressionNotTreatedAsYodaCondition() {
    let input = """
      (foo + bar)[5] != baz
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func subscriptOfUnwrappedValueNotTreatedAsYodaCondition() {
    let input = """
      foo![5] != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func subscriptOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
    let input = """
      foo /* foo */ [5] != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func subscriptOfCollectionNotTreatedAsYodaCondition() {
    let input = """
      [foo][5] != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func subscriptOfTrailingClosureNotTreatedAsYodaCondition() {
    let input = """
      foo { [5] }[0] != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func subscriptOfRhsNotMangledInYodaCondition() {
    let input = """
      [1] == foo[0]
      """
    let output = """
      foo[0] == [1]
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func tupleYodaCondition() {
    let input = """
      (5, 6) != bar
      """
    let output = """
      bar != (5, 6)
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func labeledTupleYodaCondition() {
    let input = """
      (foo: 5, bar: 6) != baz
      """
    let output = """
      baz != (foo: 5, bar: 6)
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func nestedTupleYodaCondition() {
    let input = """
      (5, (6, 7)) != baz
      """
    let output = """
      baz != (5, (6, 7))
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func functionCallNotTreatedAsYodaCondition() {
    let input = """
      foo(5) != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func callOfParenthesizedExpressionNotTreatedAsYodaCondition() {
    let input = """
      (foo + bar)(5) != baz
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func callOfUnwrappedValueNotTreatedAsYodaCondition() {
    let input = """
      foo!(5) != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func callOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
    let input = """
      foo /* foo */ (5) != bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func callOfRhsNotMangledInYodaCondition() {
    let input = """
      (1, 2) == foo(0)
      """
    let output = """
      foo(0) == (1, 2)
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func trailingClosureOnRhsNotMangledInYodaCondition() {
    let input = """
      (1, 2) == foo { $0 }
      """
    let output = """
      foo { $0 } == (1, 2)
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func yodaConditionInIfStatement() {
    let input = """
      if 5 != foo {}
      """
    let output = """
      if foo != 5 {}
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

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
      exclude: [.wrapConditionalBodies])
  }

  @Test func yodaConditionInSecondClauseOfIfStatement() {
    let input = """
      if foo, 5 != bar {}
      """
    let output = """
      if foo, bar != 5 {}
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func yodaConditionInExpression() {
    let input = """
      let foo = 5 < bar
      baz()
      """
    let output = """
      let foo = bar > 5
      baz()
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func yodaConditionInExpressionWithTrailingClosure() {
    let input = """
      let foo = 5 < bar { baz() }
      """
    let output = """
      let foo = bar { baz() } > 5
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func yodaConditionInFunctionCall() {
    let input = """
      foo(5 < bar)
      """
    let output = """
      foo(bar > 5)
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func yodaConditionFollowedByExpression() {
    let input = """
      5 == foo + 6
      """
    let output = """
      foo + 6 == 5
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func prefixExpressionYodaCondition() {
    let input = """
      !false == foo
      """
    let output = """
      foo == !false
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func prefixExpressionYodaCondition2() {
    let input = """
      true == !foo
      """
    let output = """
      !foo == true
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func postfixExpressionYodaCondition() {
    let input = """
      5<*> == foo
      """
    let output = """
      foo == 5<*>
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func doublePostfixExpressionYodaCondition() {
    let input = """
      5!! == foo
      """
    let output = """
      foo == 5!!
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func postfixExpressionNonYodaCondition() {
    let input = """
      5 == 5<*>
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func postfixExpressionNonYodaCondition2() {
    let input = """
      5<*> == 5
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func stringEqualsStringNonYodaCondition() {
    let input = """
      \"foo\" == \"bar\"
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func constantAfterNullCoalescingNonYodaCondition() {
    let input = """
      foo.last ?? -1 < bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func noMangleYodaConditionFollowedByAndOperator() {
    let input = """
      5 <= foo && foo <= 7
      """
    let output = """
      foo >= 5 && foo <= 7
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func noMangleYodaConditionFollowedByOrOperator() {
    let input = """
      5 <= foo || foo <= 7
      """
    let output = """
      foo >= 5 || foo <= 7
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func noMangleYodaConditionFollowedByParentheses() {
    let input = """
      0 <= (foo + bar)
      """
    let output = """
      (foo + bar) >= 0
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func noMangleYodaConditionInTernary() {
    let input = """
      let z = 0 < y ? 3 : 4
      """
    let output = """
      let z = y > 0 ? 3 : 4
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func noMangleYodaConditionInTernary2() {
    let input = """
      let z = y > 0 ? 0 < x : 4
      """
    let output = """
      let z = y > 0 ? x > 0 : 4
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func noMangleYodaConditionInTernary3() {
    let input = """
      let z = y > 0 ? 3 : 0 < x
      """
    let output = """
      let z = y > 0 ? 3 : x > 0
      """
    testFormatting(for: input, output, rule: .yodaConditions)
  }

  @Test func keyPathNotMangledAndNotTreatedAsYodaCondition() {
    let input = """
      \\.foo == bar
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func enumCaseLessThanEnumCase() {
    let input = """
      #expect(!(.never < .never))
      """
    testFormatting(for: input, rule: .yodaConditions)
  }

  @Test func genericFunctionsInEqualityExpressions() {
    let input = """
      print(method<Int>() == 123)
      print(method<Int>() == intVariable)
      print(method<Int>() == IntEnum.foo.rawValue)
      print(method<String>() == "string")
      print(method<String>() == stringVariable)
      print(method<String>() == StringEnum.foo.rawValue)
      """
    testFormatting(for: input, rule: .yodaConditions)
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
