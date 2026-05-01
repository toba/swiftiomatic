// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import SwiftSyntax

/// Early exits should be used whenever possible.
///
/// This means that `if ... else { return/throw/break/continue }` constructs should be replaced by
/// `guard ... else { return/throw/break/continue }` constructs in order to keep indentation levels
/// low. Specifically, code of the following form:
///
/// ```swift
/// if condition {
///   trueBlock
/// } else {
///   falseBlock
///   return/throw/break/continue
/// }
/// ```
///
/// will be transformed into:
///
/// ```swift
/// guard condition else {
///   falseBlock
///   return/throw/break/continue
/// }
/// trueBlock
/// ```
///
/// Lint: `if ... else { return/throw/break/continue }` constructs will yield a lint error.
///
/// Rewrite: `if ... else { return/throw/break/continue }` constructs will be replaced with
/// equivalent `guard ... else { return/throw/break/continue }` constructs.
final class UseEarlyExits: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }

    /// Identifies this rule as being opt-in. This rule is experimental and not yet stable enough to
    /// be enabled by default.
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Compact pipeline

    /// Diagnose on the pre-traversal node so finding source locations come from the original tree.
    static func willEnter(_ node: CodeBlockItemListSyntax, context: Context) {
        for codeBlockItem in node {
            guard let exprStmt = codeBlockItem.item.as(ExpressionStmtSyntax.self),
                  let ifStatement = exprStmt.expression.as(IfExprSyntax.self),
                  let elseBody = ifStatement.elseBody?.as(CodeBlockSyntax.self),
                  Self.codeBlockEndsWithEarlyExit(elseBody) else { continue }
            Self.diagnose(.useGuardStatement, on: ifStatement, context: context)
        }
    }

    /// Replace `if/else { early-exit }` blocks with `guard ... else { ... }` . Called from
    /// `CompactSyntaxRewriter.visit(_: CodeBlockItemListSyntax)` .
    static func apply(
        _ node: CodeBlockItemListSyntax,
        context _: Context
    ) -> CodeBlockItemListSyntax {
        var newItems = [CodeBlockItemSyntax]()

        for codeBlockItem in node {
            guard let exprStmt = codeBlockItem.item.as(ExpressionStmtSyntax.self),
                  let ifStatement = exprStmt.expression.as(IfExprSyntax.self),
                  let elseBody = ifStatement.elseBody?.as(CodeBlockSyntax.self),
                  codeBlockEndsWithEarlyExit(elseBody) else {
                newItems.append(codeBlockItem)
                continue
            }

            let guardKeyword = TokenSyntax.keyword(
                .guard,
                leadingTrivia: ifStatement.ifKeyword.leadingTrivia,
                trailingTrivia: .spaces(1)
            )
            let guardStatement = GuardStmtSyntax(
                guardKeyword: guardKeyword,
                conditions: ifStatement.conditions,
                elseKeyword: TokenSyntax.keyword(.else, trailingTrivia: .spaces(1)),
                body: elseBody
            )

            newItems.append(CodeBlockItemSyntax(item: .stmt(StmtSyntax(guardStatement))))

            for trueStmt in ifStatement.body.statements { newItems.append(trueStmt) }
        }

        return CodeBlockItemListSyntax(newItems)
    }

    fileprivate static func codeBlockEndsWithEarlyExit(_ codeBlock: CodeBlockSyntax) -> Bool {
        guard let lastStatement = codeBlock.statements.last else { return false }

        switch lastStatement.item {
            case let .stmt(stmt):
                switch Syntax(stmt).as(SyntaxEnum.self) {
                    case .returnStmt, .throwStmt, .breakStmt, .continueStmt: return true
                    default: return false
                }
            default: return false
        }
    }
}

fileprivate extension Finding.Message {
    static let useGuardStatement: Finding.Message =
        "replace this 'if/else' block with a 'guard' statement containing the early exit"
}
