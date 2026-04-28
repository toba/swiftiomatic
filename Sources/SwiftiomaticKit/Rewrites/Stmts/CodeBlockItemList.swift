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
    context: Context
) -> CodeBlockItemListSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

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

    // PreferEarlyExits — unported (legacy `SyntaxFormatRule.visit` override
    // not yet migrated to a static `transform`). Audit-only `shouldFormat`
    // call preserves rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(PreferEarlyExits.self, node: Syntax(result))

    return result
}
