//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Single-expression functions, closures, subscripts can omit `return` statement.
///
/// This includes exhaustive `if`/`switch` expressions where every branch is a single
/// `return <expr>` ([SE-0380](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0380-if-switch-expressions.md),
/// implemented in Swift 5.9).
///
/// Lint: `func <name>() { return ... }` and similar single expression constructs will yield a lint error.
///
/// Rewrite: `func <name>() { return ... }` constructs will be replaced with
///         equivalent `func <name>() { ... }` constructs.
final class RedundantReturn: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .redundancies }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Names of standard library functions that return `Never`.
    private static let neverReturningFunctions: Set<String> = [
        "fatalError", "preconditionFailure",
    ]

    // MARK: - Static transform (compact pipeline)

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        var funcDecl = node
        guard let body = funcDecl.body else { return DeclSyntax(node) }

        if let returnStmt = Self.containsSingleReturn(body.statements) {
            funcDecl.body?.statements = Self.rewrapReturnedExpression(returnStmt)
            Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
        } else if let item = Self.containsExhaustiveReturn(body.statements) {
            funcDecl.body?.statements = CodeBlockItemListSyntax(
                [Self.stripReturns(from: item, context: context)]
            )
        } else {
            return DeclSyntax(node)
        }

        return DeclSyntax(funcDecl)
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        var subscriptDecl = node
        guard let accessorBlock = subscriptDecl.accessorBlock,
              let transformed = Self.transformAccessorBlock(accessorBlock, context: context)
        else { return DeclSyntax(node) }

        subscriptDecl.accessorBlock = transformed
        return DeclSyntax(subscriptDecl)
    }

    static func transform(
        _ node: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        var binding = node
        guard let accessorBlock = binding.accessorBlock,
              let transformed = Self.transformAccessorBlock(accessorBlock, context: context)
        else { return node }

        binding.accessorBlock = transformed
        return binding
    }

    static func transform(
        _ node: ClosureExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        var closureExpr = node

        if let returnStmt = Self.containsSingleReturn(closureExpr.statements) {
            closureExpr.statements = Self.rewrapReturnedExpression(returnStmt)
            Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
        } else if let item = Self.containsExhaustiveReturn(closureExpr.statements) {
            closureExpr.statements = CodeBlockItemListSyntax(
                [Self.stripReturns(from: item, context: context)]
            )
        } else {
            return ExprSyntax(node)
        }

        return ExprSyntax(closureExpr)
    }

    // MARK: - Static helpers

    fileprivate static func transformAccessorBlock(
        _ accessorBlock: AccessorBlockSyntax,
        context: Context
    ) -> AccessorBlockSyntax? {
        switch accessorBlock.accessors {
            case var .accessors(accessors):
                guard var getter = accessors.filter({
                    $0.accessorSpecifier.tokenKind == .keyword(.get)
                }).first,
                      let getterAt = accessors.firstIndex(where: {
                          $0.accessorSpecifier.tokenKind == .keyword(.get)
                      }),
                      let body = getter.body
                else { return nil }

                if let returnStmt = Self.containsSingleReturn(body.statements) {
                    getter.body?.statements = Self.rewrapReturnedExpression(returnStmt)
                    Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
                } else if let item = Self.containsExhaustiveReturn(body.statements) {
                    getter.body?.statements = CodeBlockItemListSyntax(
                        [Self.stripReturns(from: item, context: context)]
                    )
                } else {
                    return nil
                }

                accessors[getterAt] = getter
                var newBlock = accessorBlock
                newBlock.accessors = .accessors(accessors)
                return newBlock

            case let .getter(getter):
                if let returnStmt = Self.containsSingleReturn(getter) {
                    Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
                    var newBlock = accessorBlock
                    newBlock.accessors = .getter(Self.rewrapReturnedExpression(returnStmt))
                    return newBlock
                } else if let item = Self.containsExhaustiveReturn(getter) {
                    var newBlock = accessorBlock
                    newBlock.accessors = .getter(
                        CodeBlockItemListSyntax([Self.stripReturns(from: item, context: context)])
                    )
                    return newBlock
                } else {
                    return nil
                }
        }
    }

    fileprivate static func containsExhaustiveReturn(
        _ body: CodeBlockItemListSyntax
    ) -> CodeBlockItemSyntax? {
        guard let element = body.firstAndOnly,
              let expr = Self.expressionFromItem(element)
        else { return nil }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return Self.allBranchesReturn(ifExpr) ? element : nil
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return Self.allCasesReturn(switchExpr) ? element : nil
        }

        return nil
    }

    fileprivate static func allBranchesReturn(_ ifExpr: IfExprSyntax) -> Bool {
        guard Self.branchReturns(ifExpr.body.statements) else { return false }

        switch ifExpr.elseBody {
            case let .codeBlock(elseBlock): return Self.branchReturns(elseBlock.statements)
            case let .ifExpr(elseIf): return Self.allBranchesReturn(elseIf)
            case nil: return false
        }
    }

    fileprivate static func allCasesReturn(_ switchExpr: SwitchExprSyntax) -> Bool {
        guard !switchExpr.cases.isEmpty else { return false }

        for caseItem in switchExpr.cases {
            guard let switchCase = caseItem.as(SwitchCaseSyntax.self) else { return false }
            guard Self.branchReturns(switchCase.statements) else { return false }
        }

        return true
    }

    fileprivate static func branchReturns(_ statements: CodeBlockItemListSyntax) -> Bool {
        guard let only = statements.firstAndOnly else { return false }

        if let returnStmt = only.item.as(ReturnStmtSyntax.self) {
            return returnStmt.expression != nil
        }

        if Self.isFatalCall(only) { return true }

        guard let expr = Self.expressionFromItem(only) else { return false }

        if let ifExpr = expr.as(IfExprSyntax.self) { return Self.allBranchesReturn(ifExpr) }
        if let switchExpr = expr.as(SwitchExprSyntax.self) { return Self.allCasesReturn(switchExpr) }

        return false
    }

    fileprivate static func isFatalCall(_ item: CodeBlockItemSyntax) -> Bool {
        let expr: ExprSyntax

        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
            expr = exprStmt.expression
        } else if let e = item.item.as(ExprSyntax.self) {
            expr = e
        } else {
            return false
        }

        guard let call = expr.as(FunctionCallExprSyntax.self),
              let callee = call.calledExpression.as(DeclReferenceExprSyntax.self)
        else { return false }

        return Self.neverReturningFunctions.contains(callee.baseName.text)
    }

    fileprivate static func expressionFromItem(_ item: CodeBlockItemSyntax) -> ExprSyntax? {
        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) { return exprStmt.expression }
        return item.item.as(ExprSyntax.self)
    }

    fileprivate static func stripReturns(
        from item: CodeBlockItemSyntax,
        context: Context
    ) -> CodeBlockItemSyntax {
        guard let expr = Self.expressionFromItem(item) else { return item }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return item.with(
                \.item,
                .expr(ExprSyntax(Self.stripReturnsFromIf(ifExpr, context: context)))
            )
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return item.with(
                \.item,
                .expr(ExprSyntax(Self.stripReturnsFromSwitch(switchExpr, context: context)))
            )
        }

        return item
    }

    fileprivate static func stripReturnsFromIf(
        _ ifExpr: IfExprSyntax,
        context: Context
    ) -> IfExprSyntax {
        var result = ifExpr
        result.body.statements = Self.stripBranch(ifExpr.body.statements, context: context)

        switch ifExpr.elseBody {
            case var .codeBlock(elseBlock):
                elseBlock.statements = Self.stripBranch(elseBlock.statements, context: context)
                result.elseBody = .codeBlock(elseBlock)
            case let .ifExpr(elseIf):
                result.elseBody = .ifExpr(Self.stripReturnsFromIf(elseIf, context: context))
            case nil: break
        }

        return result
    }

    fileprivate static func stripReturnsFromSwitch(
        _ switchExpr: SwitchExprSyntax,
        context: Context
    ) -> SwitchExprSyntax {
        var result = switchExpr
        var newCases = [SwitchCaseListSyntax.Element]()

        for caseItem in switchExpr.cases {
            if var switchCase = caseItem.as(SwitchCaseSyntax.self) {
                switchCase.statements = Self.stripBranch(switchCase.statements, context: context)
                newCases.append(.switchCase(switchCase))
            } else {
                newCases.append(caseItem)
            }
        }

        result.cases = SwitchCaseListSyntax(newCases)
        return result
    }

    fileprivate static func stripBranch(
        _ statements: CodeBlockItemListSyntax,
        context: Context
    ) -> CodeBlockItemListSyntax {
        guard let only = statements.firstAndOnly else { return statements }

        if Self.isFatalCall(only) { return statements }

        if let returnStmt = only.item.as(ReturnStmtSyntax.self), let expr = returnStmt.expression {
            Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
            return CodeBlockItemListSyntax([
                CodeBlockItemSyntax(
                    leadingTrivia: returnStmt.leadingTrivia,
                    item: .expr(expr.detached.with(\.trailingTrivia, [])),
                    semicolon: nil,
                    trailingTrivia: returnStmt.trailingTrivia
                )
            ])
        }

        guard let expr = Self.expressionFromItem(only) else { return statements }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return CodeBlockItemListSyntax([
                only.with(
                    \.item,
                    .expr(ExprSyntax(Self.stripReturnsFromIf(ifExpr, context: context)))
                )
            ])
        }
        if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return CodeBlockItemListSyntax([
                only.with(
                    \.item,
                    .expr(ExprSyntax(Self.stripReturnsFromSwitch(switchExpr, context: context)))
                )
            ])
        }

        return statements
    }

    fileprivate static func containsSingleReturn(
        _ body: CodeBlockItemListSyntax
    ) -> ReturnStmtSyntax? {
        guard let element = body.firstAndOnly,
              let returnStmt = element.item.as(ReturnStmtSyntax.self)
        else { return nil }

        return !returnStmt.children(viewMode: .all).isEmpty && returnStmt.expression != nil
            ? returnStmt : nil
    }

    fileprivate static func rewrapReturnedExpression(
        _ returnStmt: ReturnStmtSyntax
    ) -> CodeBlockItemListSyntax {
        .init([
            CodeBlockItemSyntax(
                leadingTrivia: returnStmt.leadingTrivia,
                item: .expr(returnStmt.expression!.detached.with(\.trailingTrivia, [])),
                semicolon: nil,
                trailingTrivia: returnStmt.trailingTrivia
            )
        ])
    }
}

fileprivate extension Finding.Message {
    static let omitReturnStatement: Finding.Message =
        "'return' can be omitted because body consists of a single expression"
}
