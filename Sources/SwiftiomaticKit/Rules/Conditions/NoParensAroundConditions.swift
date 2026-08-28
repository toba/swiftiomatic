//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Enforces rules around parentheses in conditions, matched expressions, return statements, and
/// initializer assignments.
///
/// Parentheses are not used around any condition of an `if` , `guard` , or `while` statement,
/// around the matched expression in a `switch` statement, around `return` values, or around
/// initializer values in variable/constant declarations.
///
/// Lint: If a top-most expression in a `switch` , `if` , `guard` , `while` , or `return` statement,
/// or in a variable initializer, is surrounded by parentheses, and it does not include a function
/// call with a trailing closure, a lint error is raised.
///
/// Rewrite: Parentheses around such expressions are removed, if they do not cause a parse
/// ambiguity. Specifically, parentheses are allowed if and only if the expression contains a
/// function call with a trailing closure.
final class NoParensAroundConditions: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 1030

    override class var group: ConfigurationGroup? { .conditions }

    // Diagnose against the pre-traversal node so finding source locations are accurate. The
    // transform overloads below strip the parens without diagnosing again.
    static func willEnter(_ node: ConditionElementSyntax, context: Context) {
        guard case let .expression(expr) = node.condition else { return }
        _ = minimalSingleExpression(expr, context: context, diagnose: true)
    }

    static func willEnter(_ node: SwitchExprSyntax, context: Context) {
        _ = minimalSingleExpression(node.subject, context: context, diagnose: true)
    }

    static func willEnter(_ node: RepeatStmtSyntax, context: Context) {
        _ = minimalSingleExpression(node.condition, context: context, diagnose: true)
    }

    static func willEnter(_ node: ReturnStmtSyntax, context: Context) {
        if let expr = node.expression {
            _ = minimalSingleExpression(expr, context: context, diagnose: true)
        }
    }

    static func willEnter(_ node: InitializerClauseSyntax, context: Context) {
        _ = minimalSingleExpression(node.value, context: context, diagnose: true)
    }

    static func transform(
        _ node: ConditionElementSyntax,
        original _: ConditionElementSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ConditionElementSyntax {
        guard case let .expression(condition) = node.condition,
              let stripped = minimalSingleExpression(condition, context: context)
        else { return node }
        var result = node
        result.condition = .expression(stripped)
        return result
    }

    static func transform(
        _ node: InitializerClauseSyntax,
        original _: InitializerClauseSyntax,
        parent _: Syntax?,
        context: Context
    ) -> InitializerClauseSyntax {
        guard let stripped = minimalSingleExpression(node.value, context: context) else {
            return node
        }
        var result = node
        result.value = stripped
        return result
    }

    static func transform(
        _ node: SwitchExprSyntax,
        original _: SwitchExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> SwitchExprSyntax {
        guard let stripped = minimalSingleExpression(node.subject, context: context) else {
            return node
        }
        var result = node
        result.subject = stripped
        fixKeywordTrailingTrivia(&result.switchKeyword.trailingTrivia)
        return result
    }

    static func transform(
        _ node: RepeatStmtSyntax,
        original _: RepeatStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> RepeatStmtSyntax {
        guard let stripped = minimalSingleExpression(node.condition, context: context) else {
            return node
        }
        var result = node
        result.condition = stripped
        fixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
        return result
    }

    static func transform(
        _ node: ReturnStmtSyntax,
        original _: ReturnStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ReturnStmtSyntax {
        guard let expression = node.expression,
              let stripped = minimalSingleExpression(expression, context: context)
        else { return node }
        var result = node
        result.expression = stripped
        fixKeywordTrailingTrivia(&result.returnKeyword.trailingTrivia)
        return result
    }

    // The three statements below hold no parenthesised subject of their own. Their conditions are
    // stripped through ConditionElementSyntax, so only the keyword spacing needs repair here.

    static func transform(
        _ node: GuardStmtSyntax,
        original _: GuardStmtSyntax,
        parent _: Syntax?,
        context _: Context
    ) -> GuardStmtSyntax {
        var result = node
        fixKeywordTrailingTrivia(&result.guardKeyword.trailingTrivia)
        return result
    }

    static func transform(
        _ node: IfExprSyntax,
        original _: IfExprSyntax,
        parent _: Syntax?,
        context _: Context
    ) -> IfExprSyntax {
        var result = node
        fixKeywordTrailingTrivia(&result.ifKeyword.trailingTrivia)
        return result
    }

    static func transform(
        _ node: WhileStmtSyntax,
        original _: WhileStmtSyntax,
        parent _: Syntax?,
        context _: Context
    ) -> WhileStmtSyntax {
        var result = node
        fixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
        return result
    }

    /// Strip the wrapping single-element tuple from `original` if doing so would not introduce a
    /// parse ambiguity. Returns the inner expression with the outer parens' trivia transferred onto
    /// it, or `nil` if no stripping is possible.
    ///
    /// Emits a `removeParensAroundExpression` finding when stripping is performed and `diagnose` is
    /// `true` .
    private static func minimalSingleExpression(
        _ original: ExprSyntax,
        context: Context,
        diagnose: Bool = false
    ) -> ExprSyntax? {
        guard let tuple = original.as(TupleExprSyntax.self),
              tuple.elements.count == 1,
              let expr = tuple.elements.first?.expression else { return nil }

        if let fnCall = expr.as(FunctionCallExprSyntax.self) {
            if fnCall.trailingClosure != nil { return nil }
            if fnCall.calledExpression.as(ClosureExprSyntax.self) != nil { return nil }
        }

        if diagnose {
            Self.diagnose(.removeParensAroundExpression, on: tuple.leftParen, context: context)
        }

        var result = expr
        result.leadingTrivia = tuple.leftParen.leadingTrivia
        result.trailingTrivia = tuple.rightParen.trailingTrivia
        return result
    }

    /// Ensure the trailing trivia of a control-flow keyword has at least one space after parens are
    /// removed from the following expression.
    private static func fixKeywordTrailingTrivia(_ trivia: inout Trivia) {
        guard trivia.isEmpty else { return }
        trivia = [.spaces(1)]
    }
}

fileprivate extension Finding.Message {
    static let removeParensAroundExpression: Finding.Message =
        "remove the parentheses around this expression"
}
