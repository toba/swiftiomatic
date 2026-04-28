import SwiftSyntax

/// Compact-pipeline merge of all `CodeBlockItemListSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldFormat(<RuleType>.self,
/// node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteCodeBlockItemList(
    _ node: CodeBlockItemListSyntax,
    parent: Syntax?,
    context: Context
) -> CodeBlockItemListSyntax {
    var result = node
    // EmptyExtensions
    if context.shouldFormat(EmptyExtensions.self, node: Syntax(result)) {
        result = EmptyExtensions.transform(result, parent: parent, context: context)
    }

    // NoAssignmentInExpressions
    if context.shouldFormat(NoAssignmentInExpressions.self, node: Syntax(result)) {
        result = NoAssignmentInExpressions.transform(result, parent: parent, context: context)
    }

    // NoSemicolons
    if context.shouldFormat(NoSemicolons.self, node: Syntax(result)) {
        result = NoSemicolons.transform(result, parent: parent, context: context)
    }

    // OneDeclarationPerLine
    if context.shouldFormat(OneDeclarationPerLine.self, node: Syntax(result)) {
        result = OneDeclarationPerLine.transform(result, parent: parent, context: context)
    }

    // PreferConditionalExpression
    if context.shouldFormat(PreferConditionalExpression.self, node: Syntax(result)) {
        result = PreferConditionalExpression.transform(result, parent: parent, context: context)
    }

    // PreferIfElseChain
    if context.shouldFormat(PreferIfElseChain.self, node: Syntax(result)) {
        result = PreferIfElseChain.transform(result, parent: parent, context: context)
    }

    // PreferTernary
    if context.shouldFormat(PreferTernary.self, node: Syntax(result)) {
        result = PreferTernary.transform(result, parent: parent, context: context)
    }

    // RedundantLet
    if context.shouldFormat(RedundantLet.self, node: Syntax(result)) {
        result = RedundantLet.transform(result, parent: parent, context: context)
    }

    // RedundantProperty
    if context.shouldFormat(RedundantProperty.self, node: Syntax(result)) {
        result = RedundantProperty.transform(result, parent: parent, context: context)
    }

    // PreferEarlyExits — converts `if cond { ... } else { ...; return/throw/
    // break/continue }` into `guard cond else { ... }; ...`. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Conditions/PreferEarlyExits.swift`.
    if context.shouldFormat(PreferEarlyExits.self, node: Syntax(result)) {
        result = applyPreferEarlyExits(result, context: context)
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

        PreferEarlyExits.diagnose(.useGuardStatement, on: ifStatement, context: context)

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
