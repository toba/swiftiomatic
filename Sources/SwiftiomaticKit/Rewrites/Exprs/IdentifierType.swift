import SwiftSyntax

/// Compact-pipeline merge of all `IdentifierTypeSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
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
