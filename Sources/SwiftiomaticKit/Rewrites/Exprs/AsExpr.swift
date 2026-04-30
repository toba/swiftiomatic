import SwiftSyntax

/// Compact-pipeline merge of all `AsExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
func rewriteAsExpr(
    _ node: AsExprSyntax,
    parent: Syntax?,
    context: Context
) -> ExprSyntax {
    let result = node

    // NoForceCast — diagnostic-only (lint warning on `as!`). No rewrite; the
    // safe replacement depends on caller intent.
    if context.shouldRewrite(NoForceCast.self, at: Syntax(result)),
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
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(result)),
       result.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
        return NoForceUnwrap.rewriteAsExpr(result, context: context)
    }

    return ExprSyntax(result)
}

extension Finding.Message {
    fileprivate static func doNotForceCast(name: String) -> Finding.Message {
        "do not force cast to '\(name)'"
    }
}
