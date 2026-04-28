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
        let parent = Syntax(node).parent
        let decl = super.visit(node)
        guard let concrete = decl.as(FunctionDeclSyntax.self) else { return decl }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard var funcDecl = Optional(node),
              let body = funcDecl.body
        else { return DeclSyntax(node) }

        if let returnStmt = containsSingleReturn(body.statements) {
            funcDecl.body?.statements = rewrapReturnedExpression(returnStmt)
            Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
        } else if let item = containsExhaustiveReturn(body.statements) {
            funcDecl.body?.statements = CodeBlockItemListSyntax([stripReturns(from: item, context: context)])
        } else {
            return DeclSyntax(node)
        }

        return .init(funcDecl)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        let parent = Syntax(node).parent
        let decl = super.visit(node)
        guard let concrete = decl.as(SubscriptDeclSyntax.self) else { return decl }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        var subscriptDecl = node
        guard let accessorBlock = subscriptDecl.accessorBlock,
              let transformed = transformAccessorBlock(accessorBlock, context: context)
        else { return DeclSyntax(node) }

        subscriptDecl.accessorBlock = transformed
        return .init(subscriptDecl)
    }

    override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        Self.transform(node, parent: Syntax(node).parent, context: context)
    }

    static func transform(
        _ node: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        var binding = node

        guard let accessorBlock = binding.accessorBlock,
              let transformed = transformAccessorBlock(accessorBlock, context: context)
        else { return node }

        binding.accessorBlock = transformed
        return binding
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        let parent = Syntax(node).parent
        let expr = super.visit(node)
        guard let concrete = expr.as(ClosureExprSyntax.self) else { return expr }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ node: ClosureExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        var closureExpr = node

        if let returnStmt = containsSingleReturn(closureExpr.statements) {
            closureExpr.statements = rewrapReturnedExpression(returnStmt)
            Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
        } else if let item = containsExhaustiveReturn(closureExpr.statements) {
            closureExpr.statements = CodeBlockItemListSyntax([stripReturns(from: item, context: context)])
        } else {
            return ExprSyntax(node)
        }

        return .init(closureExpr)
    }

    private static func transformAccessorBlock(
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

                if let returnStmt = containsSingleReturn(body.statements) {
                    getter.body?.statements = rewrapReturnedExpression(returnStmt)
                    Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
                } else if let item = containsExhaustiveReturn(body.statements) {
                    getter.body?.statements = CodeBlockItemListSyntax([stripReturns(from: item, context: context)])
                } else {
                    return nil
                }

                accessors[getterAt] = getter
                var newBlock = accessorBlock
                newBlock.accessors = .accessors(accessors)
                return newBlock

            case let .getter(getter):
                if let returnStmt = containsSingleReturn(getter) {
                    Self.diagnose(.omitReturnStatement, on: returnStmt, context: context)
                    var newBlock = accessorBlock
                    newBlock.accessors = .getter(rewrapReturnedExpression(returnStmt))
                    return newBlock
                } else if let item = containsExhaustiveReturn(getter) {
                    var newBlock = accessorBlock
                    newBlock
                        .accessors = .getter(CodeBlockItemListSyntax([stripReturns(from: item, context: context)]))
                    return newBlock
                } else {
                    return nil
                }
        }
    }

    // MARK: - Multi-branch analysis (SE-0380)

    /// Returns the single `CodeBlockItemSyntax` if it's an exhaustive `if`/`switch`
    /// where every terminal branch is a single `return <expr>`.
    private static func containsExhaustiveReturn(_ body: CodeBlockItemListSyntax) -> CodeBlockItemSyntax? {
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

    private static func allBranchesReturn(_ ifExpr: IfExprSyntax) -> Bool {
        guard branchReturns(ifExpr.body.statements) else { return false }

        switch ifExpr.elseBody {
            case let .codeBlock(elseBlock): return branchReturns(elseBlock.statements)
            case let .ifExpr(elseIf): return allBranchesReturn(elseIf)
            case nil: return false
        }
    }

    private static func allCasesReturn(_ switchExpr: SwitchExprSyntax) -> Bool {
        guard !switchExpr.cases.isEmpty else { return false }

        for caseItem in switchExpr.cases {
            guard let switchCase = caseItem.as(SwitchCaseSyntax.self) else { return false }
            guard branchReturns(switchCase.statements) else { return false }
        }

        return true
    }

    /// Whether a branch contains a single `return <expr>`, a `Never`-returning call
    /// (e.g. `fatalError`), or a single nested exhaustive if/switch where every branch returns.
    private static func branchReturns(_ statements: CodeBlockItemListSyntax) -> Bool {
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
    private static func isFatalCall(_ item: CodeBlockItemSyntax) -> Bool {
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
    private static func expressionFromItem(_ item: CodeBlockItemSyntax) -> ExprSyntax? {
        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) { return exprStmt.expression }
        return item.item.as(ExprSyntax.self)
    }

    /// Recursively strips `return` from every terminal branch, emitting a diagnostic on each.
    private static func stripReturns(from item: CodeBlockItemSyntax, context: Context) -> CodeBlockItemSyntax {
        guard let expr = expressionFromItem(item) else { return item }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return item.with(\.item, .expr(ExprSyntax(stripReturnsFromIf(ifExpr, context: context))))
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return item.with(\.item, .expr(ExprSyntax(stripReturnsFromSwitch(switchExpr, context: context))))
        }

        return item
    }

    private static func stripReturnsFromIf(_ ifExpr: IfExprSyntax, context: Context) -> IfExprSyntax {
        var result = ifExpr
        result.body.statements = stripBranch(ifExpr.body.statements, context: context)

        switch ifExpr.elseBody {
            case var .codeBlock(elseBlock):
                elseBlock.statements = stripBranch(elseBlock.statements, context: context)
                result.elseBody = .codeBlock(elseBlock)
            case let .ifExpr(elseIf): result.elseBody = .ifExpr(stripReturnsFromIf(elseIf, context: context))
            case nil: break
        }

        return result
    }

    private static func stripReturnsFromSwitch(_ switchExpr: SwitchExprSyntax, context: Context) -> SwitchExprSyntax {
        var result = switchExpr
        var newCases = [SwitchCaseListSyntax.Element]()

        for caseItem in switchExpr.cases {
            if var switchCase = caseItem.as(SwitchCaseSyntax.self) {
                switchCase.statements = stripBranch(switchCase.statements, context: context)
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
    private static func stripBranch(_ statements: CodeBlockItemListSyntax, context: Context) -> CodeBlockItemListSyntax {
        guard let only = statements.firstAndOnly else { return statements }

        // Never-returning calls don't have a `return` to strip.
        if isFatalCall(only) { return statements }

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

        // Nested if/switch expression
        guard let expr = expressionFromItem(only) else { return statements }

        if let ifExpr = expr.as(IfExprSyntax.self) {
            return CodeBlockItemListSyntax([
                only.with(\.item, .expr(ExprSyntax(stripReturnsFromIf(ifExpr, context: context))))
            ])
        }
        if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return CodeBlockItemListSyntax([
                only.with(\.item, .expr(ExprSyntax(stripReturnsFromSwitch(switchExpr, context: context))))
            ])
        }

        return statements
    }

    // MARK: - Single-expression analysis

    private static func containsSingleReturn(_ body: CodeBlockItemListSyntax) -> ReturnStmtSyntax? {
        guard let element = body.firstAndOnly,
              let returnStmt = element.item.as(ReturnStmtSyntax.self)
        else { return nil }

        return !returnStmt.children(viewMode: .all).isEmpty && returnStmt.expression != nil
            ? returnStmt : nil
    }

    private static func rewrapReturnedExpression(
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
