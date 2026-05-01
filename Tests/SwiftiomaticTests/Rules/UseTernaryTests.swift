@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseTernaryTests: RuleTesting {

    // MARK: - Return statements

    @Test func convertsSimpleIfElseReturn() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    1️⃣if condition {
                        return foo()
                    } else {
                        return bar()
                    }
                }
                """,
            expected: """
                func test() {
                    return condition ? foo() : bar()
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    @Test func convertsIfElseReturnWithComplexCondition() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    1️⃣if trailingCount == 1 {
                        return convertSingle(
                            callNode: callNode,
                            closureArg: closureArgs[0],
                            remainingArgs: remainingArgs,
                            funcName: funcName,
                            originalNode: node
                        )
                    } else {
                        return convertMultiple(
                            callNode: callNode,
                            closureArgs: closureArgs,
                            remainingArgs: remainingArgs,
                            originalNode: node
                        )
                    }
                }
                """,
            expected: """
                func test() {
                    return trailingCount == 1\(" ")
                ? convertSingle(
                            callNode: callNode,
                            closureArg: closureArgs[0],
                            remainingArgs: remainingArgs,
                            funcName: funcName,
                            originalNode: node
                        )\(" ")
                : convertMultiple(
                            callNode: callNode,
                            closureArgs: closureArgs,
                            remainingArgs: remainingArgs,
                            originalNode: node
                        )
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    @Test func convertsReturnWithLiterals() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() -> Int {
                    1️⃣if flag {
                        return 1
                    } else {
                        return 0
                    }
                }
                """,
            expected: """
                func test() -> Int {
                    return flag ? 1 : 0
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    // MARK: - No-ops

    @Test func doesNotConvertElseIfChain() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if conditionA {
                        return foo()
                    } else if conditionB {
                        return bar()
                    } else {
                        return baz()
                    }
                }
                """,
            expected: """
                func test() {
                    if conditionA {
                        return foo()
                    } else if conditionB {
                        return bar()
                    } else {
                        return baz()
                    }
                }
                """)
    }

    @Test func doesNotConvertMultiStatementBranch() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        log("true")
                        return foo()
                    } else {
                        return bar()
                    }
                }
                """,
            expected: """
                func test() {
                    if condition {
                        log("true")
                        return foo()
                    } else {
                        return bar()
                    }
                }
                """)
    }

    @Test func doesNotConvertMixedReturnAndExpression() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        return foo()
                    } else {
                        bar()
                    }
                }
                """,
            expected: """
                func test() {
                    if condition {
                        return foo()
                    } else {
                        bar()
                    }
                }
                """)
    }

    @Test func doesNotConvertIfWithoutElse() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        return foo()
                    }
                }
                """,
            expected: """
                func test() {
                    if condition {
                        return foo()
                    }
                }
                """)
    }

    @Test func doesNotConvertBareReturnWithoutExpression() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        return
                    } else {
                        return
                    }
                }
                """,
            expected: """
                func test() {
                    if condition {
                        return
                    } else {
                        return
                    }
                }
                """)
    }

    @Test func doesNotConvertBareExpressions() {
        assertFormatting(
            UseTernary.self,
            input: """
                let x = {
                    if condition {
                        foo
                    } else {
                        bar
                    }
                }
                """,
            expected: """
                let x = {
                    if condition {
                        foo
                    } else {
                        bar
                    }
                }
                """)
    }

    // MARK: - Assignment statements

    @Test func convertsSimpleIfElseAssignment() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    var result = 0
                    1️⃣if condition {
                        result = foo()
                    } else {
                        result = bar()
                    }
                }
                """,
            expected: """
                func test() {
                    var result = 0
                    result = condition ? foo() : bar()
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    @Test func convertsAssignmentWithComplexExpressions() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    1️⃣if kind == .chained {
                        result = ExprSyntax(
                            OptionalChainingExprSyntax(
                                expression: result,
                                trailingTrivia: trivia
                            )
                        )
                    } else {
                        result = ExprSyntax(
                            ForceUnwrapExprSyntax(
                                expression: result,
                                trailingTrivia: trivia
                            )
                        )
                    }
                }
                """,
            expected: """
                func test() {
                    result = kind == .chained\(" ")
                ? ExprSyntax(
                            OptionalChainingExprSyntax(
                                expression: result,
                                trailingTrivia: trivia
                            )
                        )\(" ")
                : ExprSyntax(
                            ForceUnwrapExprSyntax(
                                expression: result,
                                trailingTrivia: trivia
                            )
                        )
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    @Test func convertsAssignmentWithMemberAccess() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    1️⃣if flag {
                        self.value = trueValue
                    } else {
                        self.value = falseValue
                    }
                }
                """,
            expected: """
                func test() {
                    self.value = flag ? trueValue : falseValue
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    @Test func doesNotConvertAssignmentToDifferentVariables() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        x = foo()
                    } else {
                        y = bar()
                    }
                }
                """,
            expected: """
                func test() {
                    if condition {
                        x = foo()
                    } else {
                        y = bar()
                    }
                }
                """)
    }

    @Test func doesNotConvertMixedReturnAndAssignment() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        return foo()
                    } else {
                        result = bar()
                    }
                }
                """,
            expected: """
                func test() {
                    if condition {
                        return foo()
                    } else {
                        result = bar()
                    }
                }
                """)
    }

    @Test func doesNotConvertCompoundAssignment() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        result += foo()
                    } else {
                        result += bar()
                    }
                }
                """,
            expected: """
                func test() {
                    if condition {
                        result += foo()
                    } else {
                        result += bar()
                    }
                }
                """)
    }

    // MARK: - if-return + trailing-return pair

    @Test func convertsIfReturnFollowedByReturn() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() -> [String] {
                    1️⃣if validCount == 1 { return [] }
                    return [error("Exactly one schema in 'oneOf' must match, but \\(validCount) matched")]
                }
                """,
            expected: """
                func test() -> [String] {
                    return validCount == 1\(" ")
                ? []\(" ")
                : [error("Exactly one schema in 'oneOf' must match, but \\(validCount) matched")]
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    @Test func convertsIfReturnMultilineFollowedByReturn() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() -> Int {
                    1️⃣if flag {
                        return 1
                    }
                    return 0
                }
                """,
            expected: """
                func test() -> Int {
                    return flag ? 1 : 0
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "use ternary conditional expression for simple if-else")
            ])
    }

    @Test func doesNotConvertIfReturnWithoutTrailingReturn() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if condition {
                        return
                    }
                    doSomething()
                }
                """,
            expected: """
                func test() {
                    if condition {
                        return
                    }
                    doSomething()
                }
                """)
    }

    @Test func doesNotConvertIfReturnPairWithOptionalBinding() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() -> Int {
                    if let value = optional { return value }
                    return fallback
                }
                """,
            expected: """
                func test() -> Int {
                    if let value = optional { return value }
                    return fallback
                }
                """)
    }

    @Test func doesNotConvertIfReturnPairWithMultipleStatements() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() -> Int {
                    if condition {
                        log("hi")
                        return 1
                    }
                    return 0
                }
                """,
            expected: """
                func test() -> Int {
                    if condition {
                        log("hi")
                        return 1
                    }
                    return 0
                }
                """)
    }

    @Test func doesNotConvertOptionalBinding() {
        assertFormatting(
            UseTernary.self,
            input: """
                func test() {
                    if let value = optional {
                        return value
                    } else {
                        return fallback
                    }
                }
                """,
            expected: """
                func test() {
                    if let value = optional {
                        return value
                    } else {
                        return fallback
                    }
                }
                """)
    }
}
