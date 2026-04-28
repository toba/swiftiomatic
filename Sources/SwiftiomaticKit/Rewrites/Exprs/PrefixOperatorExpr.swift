import SwiftSyntax

/// Compact-pipeline merge of all `PrefixOperatorExprSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
///
/// Returns `ExprSyntax` (not `PrefixOperatorExprSyntax`) because
/// `PreferExplicitFalse` rewrites `!x` to `x == false` (an
/// `InfixOperatorExprSyntax`). The standard `applyRule` helper can't widen the
/// node kind, so we dispatch directly.
func rewritePrefixOperatorExpr(
    _ node: PrefixOperatorExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    var result = ExprSyntax(node)

    if context.shouldFormat(PreferExplicitFalse.self, node: Syntax(result)) {
        if let prefix = result.as(PrefixOperatorExprSyntax.self) {
            result = PreferExplicitFalse.transform(prefix, parent: parent, context: context)
        }
    }

    return result
}
