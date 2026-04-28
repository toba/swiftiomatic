import SwiftSyntax

/// Compact-pipeline merge of all `IdentifierTypeSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteIdentifierType(
    _ node: IdentifierTypeSyntax,
    parent: Syntax?,
    context: Context
) -> TypeSyntax {
    var result: TypeSyntax = TypeSyntax(node)

    // PreferShorthandTypeNames — `Array<T>`/`Dictionary<K,V>`/`Optional<T>` →
    // `[T]`/`[K: V]`/`T?`. May change the concrete type to ArrayType, etc.
    if context.shouldFormat(PreferShorthandTypeNames.self, node: Syntax(result)),
       let typed = result.as(IdentifierTypeSyntax.self)
    {
        result = PreferShorthandTypeNames.transform(typed, parent: parent, context: context)
    }

    return result
}
