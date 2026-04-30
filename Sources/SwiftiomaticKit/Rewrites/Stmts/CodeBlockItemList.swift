import SwiftSyntax

/// Compact-pipeline merge of all `CodeBlockItemListSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteCodeBlockItemList(
    _ node: CodeBlockItemListSyntax,
    parent: Syntax?,
    context: Context
) -> CodeBlockItemListSyntax {
    var result = node
    // EmptyExtensions
    if context.shouldRewrite(EmptyExtensions.self, at: Syntax(result)) {
        result = EmptyExtensions.transform(result, parent: parent, context: context)
    }

    // NoAssignmentInExpressions
    if context.shouldRewrite(NoAssignmentInExpressions.self, at: Syntax(result)) {
        result = NoAssignmentInExpressions.transform(result, parent: parent, context: context)
    }

    // NoSemicolons
    if context.shouldRewrite(NoSemicolons.self, at: Syntax(result)) {
        result = NoSemicolons.transform(result, parent: parent, context: context)
    }

    // OneDeclarationPerLine
    if context.shouldRewrite(OneDeclarationPerLine.self, at: Syntax(result)) {
        result = OneDeclarationPerLine.transform(result, parent: parent, context: context)
    }

    // PreferConditionalExpression
    if context.shouldRewrite(PreferConditionalExpression.self, at: Syntax(result)) {
        result = PreferConditionalExpression.transform(result, parent: parent, context: context)
    }

    // PreferIfElseChain
    if context.shouldRewrite(PreferIfElseChain.self, at: Syntax(result)) {
        result = PreferIfElseChain.transform(result, parent: parent, context: context)
    }

    // PreferTernary
    if context.shouldRewrite(PreferTernary.self, at: Syntax(result)) {
        result = PreferTernary.transform(result, parent: parent, context: context)
    }

    // RedundantLet
    if context.shouldRewrite(RedundantLet.self, at: Syntax(result)) {
        result = RedundantLet.transform(result, parent: parent, context: context)
    }

    // RedundantProperty
    if context.shouldRewrite(RedundantProperty.self, at: Syntax(result)) {
        result = RedundantProperty.transform(result, parent: parent, context: context)
    }

    // PreferEarlyExits — converts `if cond { ... } else { ...; return/throw/
    // break/continue }` into `guard cond else { ... }; ...`. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Conditions/PreferEarlyExits.swift`.
    if context.shouldRewrite(PreferEarlyExits.self, at: Syntax(result)) {
        result = applyPreferEarlyExits(result, context: context)
    }

    // NoGuardInTests — convert `guard` statements in test functions to
    // `try #require(...)` / `#expect(...)` / XCTest equivalents. Gated on
    // `state.insideTestFunction` set by the willEnter hooks.
    if context.shouldRewrite(NoGuardInTests.self, at: Syntax(result)) {
        result = NoGuardInTests.transform(result, parent: parent, context: context)
    }

    return result
}

private func applyPreferEarlyExits(
    _ node: CodeBlockItemListSyntax,
    context: Context
) -> CodeBlockItemListSyntax {
    var newItems = [CodeBlockItemSyntax]()

    for codeBlockItem in node {
        guard let exprStmt = codeBlockItem.item.as(ExpressionStmtSyntax.self),
              let ifStatement = exprStmt.expression.as(IfExprSyntax.self),
              let elseBody = ifStatement.elseBody?.as(CodeBlockSyntax.self),
              codeBlockEndsWithEarlyExit(elseBody)
        else {
            newItems.append(codeBlockItem)
            continue
        }

        // Diagnostic emitted in `PreferEarlyExits.willEnter(_:context:)` against
        // the pre-traversal node so finding locations come from the original tree.

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

private func codeBlockEndsWithEarlyExit(_ codeBlock: CodeBlockSyntax) -> Bool {
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

extension Finding.Message {
    fileprivate static let useGuardStatement: Finding.Message =
        "replace this 'if/else' block with a 'guard' statement containing the early exit"
}
