import SwiftSyntax

/// Compact-pipeline merge of all `AccessorBlockSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`. The generator emits a thin override that fires
/// `willEnter`/`didExit` hooks before/after `super.visit`; this function
/// performs only the post-traversal transforms.
func rewriteAccessorBlock(
    _ node: AccessorBlockSyntax,
    parent: Syntax?,
    context: Context
) -> AccessorBlockSyntax {
    var result = node

    // ProtocolAccessorOrder
    if context.shouldFormat(ProtocolAccessorOrder.self, node: Syntax(result)) {
        result = ProtocolAccessorOrder.transform(result, parent: parent, context: context)
    }

    return result
}
