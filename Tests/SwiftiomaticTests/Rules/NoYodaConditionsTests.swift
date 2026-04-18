@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct YodaConditionsTests: RuleTesting {
  @Test func integerOnLeft() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣5 == foo {}
        """,
      expected: """
        if foo == 5 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func nilOnLeft() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣nil != bar {}
        """,
      expected: """
        if bar != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func enumMemberOnLeft() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣.default == style {}
        """,
      expected: """
        if style == .default {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func boolOnLeft() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣true == flag {}
        """,
      expected: """
        if flag == true {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func stringOnLeft() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣"hello" == greeting {}
        """,
      expected: """
        if greeting == "hello" {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func lessThanFlipped() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣0 < count {}
        """,
      expected: """
        if count > 0 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func greaterThanFlipped() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣10 >= x {}
        """,
      expected: """
        if x <= 10 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func constantOnRightNotModified() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if foo == 5 {}
        if bar != nil {}
        if x > 0 {}
        """,
      expected: """
        if foo == 5 {}
        if bar != nil {}
        if x > 0 {}
        """,
      findings: []
    )
  }

  @Test func bothConstantsNotModified() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1 == 1 {}
        if nil == nil {}
        """,
      expected: """
        if 1 == 1 {}
        if nil == nil {}
        """,
      findings: []
    )
  }

  @Test func bothVariablesNotModified() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if foo == bar {}
        """,
      expected: """
        if foo == bar {}
        """,
      findings: []
    )
  }

  @Test func floatOnLeft() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if 1️⃣3.14 == pi {}
        """,
      expected: """
        if pi == 3.14 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat reference tests

  @Test func floatGreaterYodaCondition() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        1️⃣5.1 > foo
        """,
      expected: """
        foo < 5.1
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func stringNotEqualYodaCondition() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        1️⃣"foo" != bar
        """,
      expected: """
        bar != "foo"
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func subscriptNotTreatedAsYodaCondition() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        foo[5] != bar
        """,
      expected: """
        foo[5] != bar
        """,
      findings: []
    )
  }

  @Test func functionCallNotTreatedAsYodaCondition() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        foo(5) != bar
        """,
      expected: """
        foo(5) != bar
        """,
      findings: []
    )
  }

  @Test func yodaConditionInSecondClauseOfIfStatement() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        if foo, 1️⃣5 != bar {}
        """,
      expected: """
        if foo, bar != 5 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func yodaConditionInExpression() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        let foo = 1️⃣5 < bar
        baz()
        """,
      expected: """
        let foo = bar > 5
        baz()
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func yodaConditionInExpressionWithTrailingClosure() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        let foo = 1️⃣5 < bar { baz() }
        """,
      expected: """
        let foo = bar { baz() } > 5
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func yodaConditionInFunctionCall() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        foo(1️⃣5 < bar)
        """,
      expected: """
        foo(bar > 5)
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func yodaConditionFollowedByExpression() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        1️⃣5 == foo + 6
        """,
      expected: """
        foo + 6 == 5
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func prefixExpressionYodaCondition() {
    // true == !foo → !foo == true (true is constant, !foo is not)
    assertFormatting(
      NoYodaConditions.self,
      input: """
        1️⃣true == !foo
        """,
      expected: """
        !foo == true
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func constantAfterNullCoalescingNonYodaCondition() {
    // ?? has higher precedence than <, so this is (foo.last ?? -1) < bar
    assertFormatting(
      NoYodaConditions.self,
      input: """
        foo.last ?? -1 < bar
        """,
      expected: """
        foo.last ?? -1 < bar
        """,
      findings: []
    )
  }

  @Test func noMangleYodaConditionFollowedByAndOperator() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        1️⃣5 <= foo && foo <= 7
        """,
      expected: """
        foo >= 5 && foo <= 7
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func noMangleYodaConditionFollowedByOrOperator() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        1️⃣5 <= foo || foo <= 7
        """,
      expected: """
        foo >= 5 || foo <= 7
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func noMangleYodaConditionFollowedByParentheses() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        1️⃣0 <= (foo + bar)
        """,
      expected: """
        (foo + bar) >= 0
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func noMangleYodaConditionInTernary() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        let z = 1️⃣0 < y ? 3 : 4
        """,
      expected: """
        let z = y > 0 ? 3 : 4
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func noMangleYodaConditionInTernary2() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        let z = y > 0 ? 1️⃣0 < x : 4
        """,
      expected: """
        let z = y > 0 ? x > 0 : 4
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func noMangleYodaConditionInTernary3() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        let z = y > 0 ? 3 : 1️⃣0 < x
        """,
      expected: """
        let z = y > 0 ? 3 : x > 0
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func keyPathNotTreatedAsYodaCondition() {
    assertFormatting(
      NoYodaConditions.self,
      input: """
        \\.foo == bar
        """,
      expected: """
        \\.foo == bar
        """,
      findings: []
    )
  }

  @Test func enumCaseLessThanEnumCase() {
    // Both sides constant — not flagged
    assertFormatting(
      NoYodaConditions.self,
      input: """
        XCTAssertFalse(.never < .never)
        """,
      expected: """
        XCTAssertFalse(.never < .never)
        """,
      findings: []
    )
  }

  @Test func genericFunctionsInEqualityExpressions() {
    // Function calls on LHS — not constant, not flagged
    assertFormatting(
      NoYodaConditions.self,
      input: """
        print(method<Int>() == 123)
        print(method<Int>() == intVariable)
        print(method<String>() == "string")
        print(method<String>() == stringVariable)
        """,
      expected: """
        print(method<Int>() == 123)
        print(method<Int>() == intVariable)
        print(method<String>() == "string")
        print(method<String>() == stringVariable)
        """,
      findings: []
    )
  }
}
