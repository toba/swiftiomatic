import SwiftSyntax

/// Compact-pipeline merge of all `AsExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteAsExpr(
    _ node: AsExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    let result = node

    // NoForceCast — diagnostic-only (lint warning on `as!`). No rewrite; the
    // safe replacement depends on caller intent.
    if context.shouldFormat(NoForceCast.self, node: Syntax(result)),
       result.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
        NoForceCast.diagnose(
            .doNotForceCast(name: result.type.trimmedDescription),
            on: result.asKeyword,
            context: context
        )
    }

    // NoForceUnwrap — `as!` → `as?` plus chain-top wrapping in test functions.
    // Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)),
       result.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
        return noForceUnwrapRewriteAsExpr(result, context: context)
    }

    return ExprSyntax(result)
}

extension Finding.Message {
    fileprivate static func doNotForceCast(name: String) -> Finding.Message {
        "do not force cast to '\(name)'"
    }
}
