@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferTernaryTests: RuleTesting {

    // MARK: - Return statements

    @Test func convertsSimpleIfElseReturn() {
        assertFormatting(
            PreferTernary.self,
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
            PreferTernary.self,
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
                    return trailingCount == 1 ? convertSingle(
                            callNode: callNode,
                            closureArg: closureArgs[0],
                            remainingArgs: remainingArgs,
                            funcName: funcName,
                            originalNode: node
                        ) : convertMultiple(
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
            PreferTernary.self,
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
            PreferTernary.self,
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
            PreferTernary.self,
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
            PreferTernary.self,
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
            PreferTernary.self,
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
            PreferTernary.self,
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
            PreferTernary.self,
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

    @Test func doesNotConvertOptionalBinding() {
        assertFormatting(
            PreferTernary.self,
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
