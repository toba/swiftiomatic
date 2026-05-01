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

/// Assignment expressions must be their own statements.
///
/// Assignment should not be used in an expression context that expects a `Void` value. For example,
/// assigning a variable within a `return` statement exiting a `Void` function is prohibited.
///
/// Lint: If an assignment expression is found in a position other than a standalone statement, a
/// lint finding is emitted.
///
/// Rewrite: A `return` statement containing an assignment expression is expanded into two separate
/// statements.
final class NoAssignmentInExpressions: StaticFormatRule<NoAssignmentInExpressionsConfiguration>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .idioms }

    static func transform(
        _ node: InfixOperatorExprSyntax,
        original _: InfixOperatorExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Diagnose any assignment that isn't directly a child of a `CodeBlockItem` (which would be
        // the case if it was its own statement).
        if isAssignmentExpression(node, context: context),
           !isStandaloneAssignmentStatement(parent: parent),
           !isInAllowedFunction(parent: parent, context: context)
        {
            Self.diagnose(.moveAssignmentToOwnStatement, on: node, context: context)
        }
        return ExprSyntax(node)
    }

    static func transform(
        _ node: CodeBlockItemListSyntax,
        original _: CodeBlockItemListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        var newItems = [CodeBlockItemSyntax]()
        newItems.reserveCapacity(node.count)

        for visitedItem in node {
            // Items have already been recursively visited by the combined rewriter's super.visit
            // (or by StructuralFormatRule.super.visit when called from the visit override). Rewrite
            // any `return <assignment>` expressions as `<assignment><newline>return` .
            switch visitedItem.item {
                case let .stmt(stmt):
                    guard var returnStmt = stmt.as(ReturnStmtSyntax.self),
                          let assignmentExpr = assignmentExpression(
                              from: returnStmt,
                              context: context
                          ) else { fallthrough }

                    // Move the leading trivia from the `return` statement to the new assignment
                    // statement, since that's a more sensible place than between the two.
                    var assignmentItem = CodeBlockItemSyntax(
                        item: .expr(ExprSyntax(assignmentExpr)))
                    assignmentItem.leadingTrivia = returnStmt.leadingTrivia
                        + returnStmt.returnKeyword.trailingTrivia.withoutLeadingSpaces()
                        + assignmentExpr.leadingTrivia
                    assignmentItem.trailingTrivia = []

                    let trailingTrivia = returnStmt.trailingTrivia
                    returnStmt.expression = nil
                    returnStmt.returnKeyword.trailingTrivia = []
                    var returnItem = CodeBlockItemSyntax(item: .stmt(StmtSyntax(returnStmt)))
                    returnItem.leadingTrivia = [.newlines(1)]
                    returnItem.trailingTrivia = trailingTrivia

                    newItems.append(assignmentItem)
                    newItems.append(returnItem)

                default: newItems.append(visitedItem)
            }
        }

        return CodeBlockItemListSyntax(newItems)
    }

    /// Extracts and returns the assignment expression in the given `return` statement, if there was
    /// one.
    private static func assignmentExpression(
        from returnStmt: ReturnStmtSyntax,
        context: Context
    ) -> InfixOperatorExprSyntax? {
        guard let returnExpr = returnStmt.expression,
              let infixOperatorExpr = returnExpr.as(InfixOperatorExprSyntax.self) else {
            return nil
        }
        return isAssignmentExpression(infixOperatorExpr, context: context)
            ? infixOperatorExpr
            : nil
    }

    /// Returns a value indicating whether the given infix operator expression is an assignment
    /// expression (either simple assignment with `=` or compound assignment with an operator like
    /// `+=` ).
    private static func isAssignmentExpression(
        _ expr: InfixOperatorExprSyntax,
        context: Context
    ) -> Bool {
        if expr.operator.is(AssignmentExprSyntax.self) { return true }
        guard let binaryOp = expr.operator.as(BinaryOperatorExprSyntax.self) else { return false }
        return context.operatorTable.infixOperator(named: binaryOp.operator.text)?
            .precedenceGroup
            == "AssignmentPrecedence"
    }

    /// Returns a value indicating whether the given node is a standalone assignment statement.
    /// Walks the captured pre-recursion parent chain.
    private static func isStandaloneAssignmentStatement(parent: Syntax?) -> Bool {
        var current = parent
        while let p = current,
              p.is(TryExprSyntax.self) || p.is(AwaitExprSyntax.self) || p.is(UnsafeExprSyntax.self)
        { current = p.parent }

        guard let p = current else { return true }
        return p.is(CodeBlockItemSyntax.self)
    }

    /// Returns true if the infix operator expression is in the (non-closure) parameters of an
    /// allowed function call. Walks the captured pre-recursion parent chain.
    private static func isInAllowedFunction(parent: Syntax?, context: Context) -> Bool {
        let allowedFunctions = context.configuration[Self.self].allowedFunctions
        var current = parent

        while let p = current {
            if p.is(CodeBlockItemSyntax.self) { break }
            if let functionCallExpr = p.as(FunctionCallExprSyntax.self),
               allowedFunctions.contains(functionCallExpr.calledExpression.trimmedDescription)
            {
                return true
            }
            current = p.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let moveAssignmentToOwnStatement: Finding.Message =
        "move this assignment expression into its own statement"
}

// MARK: - Configuration

package struct NoAssignmentInExpressionsConfiguration: SyntaxRuleValue {
    package var rewrite = true
    package var lint: Lint = .warn
    /// Function names whose argument expressions may contain assignments without triggering a
    /// finding (e.g. `XCTAssertNoThrow` accepts an expression that legitimately produces side
    /// effects).
    package var allowedFunctions: [String] = ["XCTAssertNoThrow"]

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        allowedFunctions = try container.decodeIfPresent([String].self, forKey: .allowedFunctions)
            ?? ["XCTAssertNoThrow"]
    }
}
