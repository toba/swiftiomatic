import SwiftSyntax

/// Compact-pipeline merge of all `AccessorDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`. The generator emits a thin override that fires
/// `willEnter`/`didExit` hooks before/after `super.visit`; this function
/// performs only the post-traversal transforms (currently none — only scope
/// hooks for `RedundantSelf`).
func rewriteAccessorDecl(
    _ node: AccessorDeclSyntax,
    parent: Syntax?,
    context: Context
) -> AccessorDeclSyntax {
    var result = node
    // RedundantSelf only uses willEnter/didExit on this node, which the
    // generator wires up.

    // WrapSingleLineBodies — inline didSet/willSet observer bodies.
    applyRule(
        WrapSingleLineBodies.self, to: &result,
        parent: parent, context: context,
        transform: WrapSingleLineBodies.transform
    )

    return result
}
