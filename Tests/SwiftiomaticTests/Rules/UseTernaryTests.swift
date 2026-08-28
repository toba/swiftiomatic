import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

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
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() {
                    if condition {
                        return foo()
                    }
                }
                """)
    }

    @Test func doesNotConvertBareReturnWithoutExpression() {
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
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
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() {
                    if condition {
                        return
                    }
                    doSomething()
                }
                """)
    }

    @Test func doesNotConvertIfReturnPairWithOptionalBinding() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if let value = optional { return value }
                    return fallback
                }
                """)
    }

    @Test func doesNotConvertIfReturnPairWithMultipleStatements() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if condition {
                        log("hi")
                        return 1
                    }
                    return 0
                }
                """)
    }

    @Test func doesNotConvertWhenElseReturnsSwitchExpression() {
        // `switch` (and `if`) expressions are only legal in return/throw/assignment positions —
        // never as a sub-expression of a ternary. Rewriting `if … return x; return switch …` into
        // `cond ? x : switch …` produces uncompilable code.
        assertUnchanged(
            UseTernary.self,
            source: """
                func matches(_ number: Int) -> Bool {
                    if numeric < 0 { return true }
                    return switch match {
                    case .wholeNumber: numeric == number
                    default: numeric == number.lastDigit
                    }
                }
                """)
    }

    @Test func doesNotConvertWhenIfBranchReturnsIfExpression() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if a {
                        return if b { 1 } else { 2 }
                    } else {
                        return 3
                    }
                }
                """)
    }

    @Test func doesNotConvertAssignmentWithSwitchExpression() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() {
                    if cond {
                        result = 1
                    } else {
                        result = switch x {
                        case .a: 1
                        default: 2
                        }
                    }
                }
                """)
    }

    @Test func doesNotConvertOptionalBinding() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() {
                    if let value = optional {
                        return value
                    } else {
                        return fallback
                    }
                }
                """)
    }

    // MARK: - Branches that read worse as a ternary

    @Test func doesNotConvertWhenThenBranchIsABooleanLiteral() {
        assertUnchanged(
            UseTernary.self,
            source: """
                var isTestFile: Bool {
                    if path.contains("/Tests/") { return true }
                    return lastPathComponent.hasSuffix("Tests.swift")
                }
                """)
    }

    @Test func doesNotConvertWhenElseBranchIsABooleanLiteral() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Bool {
                    if flag {
                        return other()
                    } else {
                        return false
                    }
                }
                """)
    }

    @Test func doesNotConvertAssignmentWithABooleanLiteralBranch() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() {
                    if flag {
                        result = true
                    } else {
                        result = other()
                    }
                }
                """)
    }

    @Test func doesNotConvertWhenABranchIsAlreadyATernary() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if flag { return seed }
                    return other ? left : right
                }
                """)
    }

    // MARK: - Comments block the fold

    @Test func keepsTrailingCommentOnTheFoldedIf() {
        assertUnchanged(
            UseTernary.self,
            source: """
                var isInsideTransaction: Bool {
                    if handle == nil { return false } // Support for deinit
                    return handle > 0
                }
                """)
    }

    @Test func keepsCommentInsideTheThenBranch() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if flag {
                        // the flag means the cache is warm
                        return 1
                    } else {
                        return 0
                    }
                }
                """)
    }

    @Test func keepsCommentInsideTheElseBranch() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if flag {
                        return 1
                    } else {
                        return 0  // nothing is cached yet
                    }
                }
                """)
    }

    @Test func keepsCommentOnTheCondition() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if flag {  // set by the loader
                        return 1
                    } else {
                        return 0
                    }
                }
                """)
    }

    @Test func keepsCommentOnTheTrailingReturnOfAPair() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    if flag { return 1 }
                    // zero is the documented default
                    return 0
                }
                """)
    }

    // MARK: - Ignore directives

    @Test func honorsIgnoreNextDirective() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    let seed = 1
                    // sm:ignore:next useTernary
                    if flag {
                        return seed
                    } else {
                        return 0
                    }
                }
                """)
    }

    @Test func honorsFileWideIgnoreDirective() {
        assertUnchanged(
            UseTernary.self,
            source: """
                // sm:ignore useTernary
                func test() -> Int {
                    if flag {
                        return 1
                    } else {
                        return 0
                    }
                }
                """)
    }

    @Test func honorsIgnoreNextDirectiveOnAnIfReturnPair() {
        assertUnchanged(
            UseTernary.self,
            source: """
                func test() -> Int {
                    let seed = 1
                    // sm:ignore:next useTernary
                    if flag { return seed }
                    return 0
                }
                """)
    }
}
