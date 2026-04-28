import SwiftSyntax

/// Compact-pipeline merge of all `SwitchExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
///
/// No node-local rules currently target `SwitchExprSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteSwitchExpr(
    _ node: SwitchExprSyntax,
    context: Context
) -> SwitchExprSyntax {
    var result = node
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // BlankLinesAfterSwitchCase — unported (legacy
    // `SyntaxFormatRule.visit` override; trivia handling not yet migrated
    // to a static `transform`). Audit-only `shouldFormat` call preserves
    // rule-mask gating; deferred to 4f.
    _ = context.shouldFormat(BlankLinesAfterSwitchCase.self, node: Syntax(result))

    // NoParensAroundConditions — unported (legacy `SyntaxFormatRule.visit`
    // override across multiple statement node types). Audit-only;
    // deferred to 4f.
    _ = context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result))

    // SwitchCaseIndentation — unported (legacy `SyntaxFormatRule.visit`
    // override; indentation logic not yet migrated to a static
    // `transform`). Audit-only; deferred to 4f.
    _ = context.shouldFormat(SwitchCaseIndentation.self, node: Syntax(result))

    // WrapMultilineStatementBraces — unported (same reasons as above).
    // Audit-only; deferred to 4f.
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}
