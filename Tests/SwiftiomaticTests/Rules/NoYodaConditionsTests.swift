import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct YodaConditionsTests: RuleTesting {
    private static let message = "place the constant on the right side of the comparison"

    @Test func integerOnLeft() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣5 == foo {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func nilOnLeft() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣nil != bar {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func enumMemberOnLeft() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣.default == style {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func boolOnLeft() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣true == flag {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func stringOnLeft() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣"hello" == greeting {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func lessThanReported() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣0 < count {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func greaterThanReported() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣10 >= x {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func constantOnRightNotReported() {
        assertLint(
            NoYodaConditions.self,
            """
            if foo == 5 {}
            if bar != nil {}
            if x > 0 {}
            """)
    }

    @Test func bothConstantsNotReported() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1 == 1 {}
            if nil == nil {}
            """)
    }

    @Test func bothVariablesNotReported() {
        assertLint(
            NoYodaConditions.self,
            """
            if foo == bar {}
            """)
    }

    @Test func floatOnLeft() {
        assertLint(
            NoYodaConditions.self,
            """
            if 1️⃣3.14 == pi {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    // MARK: - The rule never rewrites

    @Test func leavesAReversedOperandDSLCallAlone() {
        // The comparison builds SQL here, not a Bool. Swapping the operands emits different SQL, so
        // the rule reports the shape and changes nothing.
        assertFormatting(
            NoYodaConditions.self,
            input: """
                Team.having(2 == Team.players.count)
                Team.having(2 >= Team.players.count)
                """,
            expected: """
                Team.having(2 == Team.players.count)
                Team.having(2 >= Team.players.count)
                """)
    }

    @Test func leavesAPlainComparisonAlone() {
        assertFormatting(
            NoYodaConditions.self,
            input: """
                if 5 == foo {}
                if 0 < count {}
                """,
            expected: """
                if 5 == foo {}
                if 0 < count {}
                """)
    }

    // MARK: - Adapted from SwiftFormat reference tests

    @Test func floatGreaterYodaCondition() {
        assertLint(
            NoYodaConditions.self,
            """
            1️⃣5.1 > foo
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func stringNotEqualYodaCondition() {
        assertLint(
            NoYodaConditions.self,
            """
            1️⃣"foo" != bar
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func subscriptNotTreatedAsYodaCondition() {
        assertLint(
            NoYodaConditions.self,
            """
            foo[5] != bar
            """)
    }

    @Test func functionCallNotTreatedAsYodaCondition() {
        assertLint(
            NoYodaConditions.self,
            """
            foo(5) != bar
            """)
    }

    @Test func yodaConditionInSecondClauseOfIfStatement() {
        assertLint(
            NoYodaConditions.self,
            """
            if foo, 1️⃣5 != bar {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionInExpression() {
        assertLint(
            NoYodaConditions.self,
            """
            let foo = 1️⃣5 < bar
            baz()
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionInExpressionWithTrailingClosure() {
        assertLint(
            NoYodaConditions.self,
            """
            let foo = 1️⃣5 < bar { baz() }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionInFunctionCall() {
        assertLint(
            NoYodaConditions.self,
            """
            foo(1️⃣5 < bar)
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionFollowedByExpression() {
        assertLint(
            NoYodaConditions.self,
            """
            1️⃣5 == foo + 6
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func prefixExpressionYodaCondition() {
        // true == !foo is reported, because true is constant and !foo is not
        assertLint(
            NoYodaConditions.self,
            """
            1️⃣true == !foo
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func constantAfterNullCoalescingNonYodaCondition() {
        // ?? has higher precedence than <, so this is (foo.last ?? -1) < bar
        assertLint(
            NoYodaConditions.self,
            """
            foo.last ?? -1 < bar
            """)
    }

    @Test func yodaConditionFollowedByAndOperator() {
        assertLint(
            NoYodaConditions.self,
            """
            1️⃣5 <= foo && foo <= 7
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionFollowedByOrOperator() {
        assertLint(
            NoYodaConditions.self,
            """
            1️⃣5 <= foo || foo <= 7
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionFollowedByParentheses() {
        assertLint(
            NoYodaConditions.self,
            """
            1️⃣0 <= (foo + bar)
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionInTernary() {
        assertLint(
            NoYodaConditions.self,
            """
            let z = 1️⃣0 < y ? 3 : 4
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionInTernaryThenBranch() {
        assertLint(
            NoYodaConditions.self,
            """
            let z = y > 0 ? 1️⃣0 < x : 4
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func yodaConditionInTernaryElseBranch() {
        assertLint(
            NoYodaConditions.self,
            """
            let z = y > 0 ? 3 : 1️⃣0 < x
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)])
    }

    @Test func keyPathNotTreatedAsYodaCondition() {
        assertLint(
            NoYodaConditions.self,
            """
            \\.foo == bar
            """)
    }

    @Test func enumCaseLessThanEnumCase() {
        // Both sides constant — not flagged
        assertLint(
            NoYodaConditions.self,
            """
            XCTAssertFalse(.never < .never)
            """)
    }

    @Test func genericFunctionsInEqualityExpressions() {
        // Function calls on LHS — not constant, not flagged
        assertLint(
            NoYodaConditions.self,
            """
            print(method<Int>() == 123)
            print(method<Int>() == intVariable)
            print(method<String>() == "string")
            print(method<String>() == stringVariable)
            """)
    }
}
