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
    context: Context
) -> AccessorDeclSyntax {
    let result = node
    // No node-local transforms registered for AccessorDeclSyntax — RedundantSelf
    // only uses willEnter/didExit on this node, which the generator wires up.
    return result
}
