import SwiftSyntax

/// Compact-pipeline merge of all `AsExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteAsExpr(
    _ node: AsExprSyntax,
    context: Context
) -> AsExprSyntax {
    var result = node
    let parent: Syntax? = nil
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax  // used by audit-only calls below.

    // No ported rules currently register `static transform` for AsExprSyntax.

    // NoForceCast — diagnostic-only (lint warning on `as!`). No rewrite; the
    // safe replacement depends on caller intent. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Unsafety/NoForceCast.swift`.
    if context.shouldFormat(NoForceCast.self, node: Syntax(result)),
       result.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
        NoForceCast.diagnose(
            .doNotForceCast(name: result.type.trimmedDescription),
            on: result.asKeyword,
            context: context
        )
    }

    // NoForceUnwrap — unported (legacy `SyntaxFormatRule.visit` override
    // with file-level pre-scan state). Audit-only; deferred to 4f.
    _ = context.shouldFormat(NoForceUnwrap.self, node: Syntax(result))

    return result
}

extension Finding.Message {
    fileprivate static func doNotForceCast(name: String) -> Finding.Message {
        "do not force cast to '\(name)'"
    }
}
