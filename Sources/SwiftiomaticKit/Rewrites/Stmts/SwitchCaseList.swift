import SwiftSyntax

/// Compact-pipeline merge of all `SwitchCaseListSyntax` rewrites. Each
/// former rule's logic is gated on `context.shouldFormat(<RuleType>.self,
/// node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
///
/// No node-local rules currently target `SwitchCaseListSyntax` via the
/// compact `transform` form. The unported entries below are tracked in 4f.
func rewriteSwitchCaseList(
    _ node: SwitchCaseListSyntax,
    context: Context
) -> SwitchCaseListSyntax {
    var result = node
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // NoFallThroughOnlyCases — unported (legacy `SyntaxFormatRule.visit`
    // override; rewrite logic not yet migrated to a static `transform`).
    // Audit-only `shouldFormat` call preserves rule-mask gating; deferred
    // to 4f.
    _ = context.shouldFormat(NoFallThroughOnlyCases.self, node: Syntax(result))

    return result
}
