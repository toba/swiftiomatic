import SwiftSyntax

/// Compact-pipeline merge of all `ForStmtSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteForStmt(
    _ node: ForStmtSyntax,
    context: Context
) -> ForStmtSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // CaseLet
    if context.shouldFormat(CaseLet.self, node: Syntax(result)) {
        if let next = CaseLet.transform(result, parent: parent, context: context).as(ForStmtSyntax.self) {
            result = next
        }
    }

    // PreferWhereClausesInForLoops
    if context.shouldFormat(PreferWhereClausesInForLoops.self, node: Syntax(result)) {
        if let next = PreferWhereClausesInForLoops.transform(result, parent: parent, context: context).as(ForStmtSyntax.self) {
            result = next
        }
    }

    // RedundantEnumerated
    if context.shouldFormat(RedundantEnumerated.self, node: Syntax(result)) {
        if let next = RedundantEnumerated.transform(result, parent: parent, context: context).as(ForStmtSyntax.self) {
            result = next
        }
    }

    // UnusedArguments
    if context.shouldFormat(UnusedArguments.self, node: Syntax(result)) {
        if let next = UnusedArguments.transform(result, parent: parent, context: context).as(ForStmtSyntax.self) {
            result = next
        }
    }

    // WrapMultilineStatementBraces — unported (legacy
    // `SyntaxFormatRule.visit` override across multiple statement node
    // types). Audit-only `shouldFormat` call preserves rule-mask gating;
    // deferred to 4f.
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
