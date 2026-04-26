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
final class RedundantReturn: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .redundancies }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let decl = super.visit(node)

        guard var funcDecl = decl.as(FunctionDeclSyntax.self),
              let body = funcDecl.body
        else { return decl }

        if let returnStmt = containsSingleReturn(body.statements) {
            funcDecl.body?.statements = rewrapReturnedExpression(returnStmt)
            diagnose(.omitReturnStatement, on: returnStmt)
        } else if let item = containsExhaustiveReturn(body.statements) {
            funcDecl.body?.statements = CodeBlockItemListSyntax([stripReturns(from: item)])
        } else {
            return decl
        }

        return .init(funcDecl)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        let decl = super.visit(node)

        guard var subscriptDecl = decl.as(SubscriptDeclSyntax.self),
              let accessorBlock = subscriptDecl.accessorBlock,
              let transformed = transformAccessorBlock(accessorBlock)
        else { return decl }

        subscriptDecl.accessorBlock = transformed
        return .init(subscriptDecl)
    }

    override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        var binding = node

        guard let accessorBlock = binding.accessorBlock,
              let transformed = transformAccessorBlock(accessorBlock)
        else { return super.visit(node) }

        binding.accessorBlock = transformed
        return binding
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        let expr = super.visit(node)

        guard var closureExpr = expr.as(ClosureExprSyntax.self) else { return expr }

        if let returnStmt = containsSingleReturn(closureExpr.statements) {
            closureExpr.statements = rewrapReturnedExpression(returnStmt)
            diagnose(.omitReturnStatement, on: returnStmt)
        } else if let item = containsExhaustiveReturn(closureExpr.statements) {
            closureExpr.statements = CodeBlockItemListSyntax([stripReturns(from: item)])
        } else {
            return expr
        }

        return .init(closureExpr)
    }

    private func transformAccessorBlock(
        _ accessorBlock: AccessorBlockSyntax
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

                if let returnStmt = containsSingleReturn(body.statements) {
                    getter.body?.statements = rewrapReturnedExpression(returnStmt)
                    diagnose(.omitReturnStatement, on: returnStmt)
                } else if let item = containsExhaustiveReturn(body.statements) {
                    getter.body?.statements = CodeBlockItemListSyntax([stripReturns(from: item)])
                } else {
                    return nil
                }

                accessors[getterAt] = getter
                var newBlock = accessorBlock
                newBlock.accessors = .accessors(accessors)
                return newBlock

            case let .getter(getter):
                if let returnStmt = containsSingleReturn(getter) {
                    diagnose(.omitReturnStatement, on: returnStmt)
                    var newBlock = accessorBlock
                    newBlock.accessors = .getter(rewrapReturnedExpression(returnStmt))
                    return newBlock
                } else if let item = containsExhaustiveReturn(getter) {
                    var newBlock = accessorBlock
                    newBlock
                        .accessors = .getter(CodeBlockItemListSyntax([stripReturns(from: item)]))
                    return newBlock
                } else {
                    return nil
                }
        }
    }

    // MARK: - Multi-branch analysis (SE-0380)

    /// Returns the single `CodeBlockItemSyntax` if it's an exhaustive `if`/`switch`
    /// where every terminal branch is a single `return <expr>`.
    private func containsExhaustiveReturn(_ body: CodeBlockItemListSyntax) -> CodeBlockItemSyntax? {
        guard let element = body.firstAndOnly,
              let expr = expressionFromItem(element)
        else { return nil }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return allBranchesReturn(ifExpr) ? element : nil
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return allCasesReturn(switchExpr) ? element : nil
        }

        return nil
    }

    private func allBranchesReturn(_ ifExpr: IfExprSyntax) -> Bool {
        guard branchReturns(ifExpr.body.statements) else { return false }

        switch ifExpr.elseBody {
            case let .codeBlock(elseBlock): return branchReturns(elseBlock.statements)
            case let .ifExpr(elseIf): return allBranchesReturn(elseIf)
            case nil: return false
        }
    }

    private func allCasesReturn(_ switchExpr: SwitchExprSyntax) -> Bool {
        guard !switchExpr.cases.isEmpty else { return false }

        for caseItem in switchExpr.cases {
            guard let switchCase = caseItem.as(SwitchCaseSyntax.self) else { return false }
            guard branchReturns(switchCase.statements) else { return false }
        }

        return true
    }

    /// Whether a branch contains a single `return <expr>`, a `Never`-returning call
    /// (e.g. `fatalError`), or a single nested exhaustive if/switch where every branch returns.
    private func branchReturns(_ statements: CodeBlockItemListSyntax) -> Bool {
        guard let only = statements.firstAndOnly else { return false }

        if let returnStmt = only.item.as(ReturnStmtSyntax.self) {
            return returnStmt.expression != nil
        }

        if isFatalCall(only) { return true }

        guard let expr = expressionFromItem(only) else { return false }

        if let ifExpr = expr.as(IfExprSyntax.self) { return allBranchesReturn(ifExpr) }
        if let switchExpr = expr.as(SwitchExprSyntax.self) { return allCasesReturn(switchExpr) }

        return false
    }

    /// Names of standard library functions that return `Never`.
    private static let neverReturningFunctions: Set<String> = [
        "fatalError", "preconditionFailure",
    ]

    /// Whether the statement is a call to a `Never`-returning function like `fatalError`.
    private func isFatalCall(_ item: CodeBlockItemSyntax) -> Bool {
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

    /// Unwraps `ExpressionStmtSyntax` to get the underlying expression.
    private func expressionFromItem(_ item: CodeBlockItemSyntax) -> ExprSyntax? {
        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) { return exprStmt.expression }
        return item.item.as(ExprSyntax.self)
    }

    /// Recursively strips `return` from every terminal branch, emitting a diagnostic on each.
    private func stripReturns(from item: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
        guard let expr = expressionFromItem(item) else { return item }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return item.with(\.item, .expr(ExprSyntax(stripReturnsFromIf(ifExpr))))
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return item.with(\.item, .expr(ExprSyntax(stripReturnsFromSwitch(switchExpr))))
        }

        return item
    }

    private func stripReturnsFromIf(_ ifExpr: IfExprSyntax) -> IfExprSyntax {
        var result = ifExpr
        result.body.statements = stripBranch(ifExpr.body.statements)

        switch ifExpr.elseBody {
            case var .codeBlock(elseBlock):
                elseBlock.statements = stripBranch(elseBlock.statements)
                result.elseBody = .codeBlock(elseBlock)
            case let .ifExpr(elseIf): result.elseBody = .ifExpr(stripReturnsFromIf(elseIf))
            case nil: break
        }

        return result
    }

    private func stripReturnsFromSwitch(_ switchExpr: SwitchExprSyntax) -> SwitchExprSyntax {
        var result = switchExpr
        var newCases = [SwitchCaseListSyntax.Element]()

        for caseItem in switchExpr.cases {
            if var switchCase = caseItem.as(SwitchCaseSyntax.self) {
                switchCase.statements = stripBranch(switchCase.statements)
                newCases.append(.switchCase(switchCase))
            } else {
                newCases.append(caseItem)
            }
        }

        result.cases = SwitchCaseListSyntax(newCases)
        return result
    }

    /// Strips `return` from the single statement in a branch.
    /// Fatal branches (`fatalError`, etc.) are left unchanged.
    private func stripBranch(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        guard let only = statements.firstAndOnly else { return statements }

        // Never-returning calls don't have a `return` to strip.
        if isFatalCall(only) { return statements }

        if let returnStmt = only.item.as(ReturnStmtSyntax.self), let expr = returnStmt.expression {
            diagnose(.omitReturnStatement, on: returnStmt)
            return CodeBlockItemListSyntax([
                CodeBlockItemSyntax(
                    leadingTrivia: returnStmt.leadingTrivia,
                    item: .expr(expr.detached.with(\.trailingTrivia, [])),
                    semicolon: nil,
                    trailingTrivia: returnStmt.trailingTrivia
                )
            ])
        }

        // Nested if/switch expression
        guard let expr = expressionFromItem(only) else { return statements }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return CodeBlockItemListSyntax([
                only.with(\.item, .expr(ExprSyntax(stripReturnsFromIf(ifExpr))))
            ])
        }
        if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return CodeBlockItemListSyntax([
                only.with(\.item, .expr(ExprSyntax(stripReturnsFromSwitch(switchExpr))))
            ])
        }

        return statements
    }

    // MARK: - Single-expression analysis

    private func containsSingleReturn(_ body: CodeBlockItemListSyntax) -> ReturnStmtSyntax? {
        guard let element = body.firstAndOnly,
              let returnStmt = element.item.as(ReturnStmtSyntax.self)
        else { return nil }

        return !returnStmt.children(viewMode: .all).isEmpty && returnStmt.expression != nil
            ? returnStmt : nil
    }

    private func rewrapReturnedExpression(
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
