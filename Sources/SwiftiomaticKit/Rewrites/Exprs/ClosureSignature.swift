import SwiftSyntax

/// Compact-pipeline merge of all `ClosureSignatureSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
func rewriteClosureSignature(
    _ node: ClosureSignatureSyntax,
    parent: Syntax?,
    context: Context
) -> ClosureSignatureSyntax {
    var result = node
    // NoParensInClosureParams
    if context.shouldFormat(NoParensInClosureParams.self, node: Syntax(result)) {
        result = NoParensInClosureParams.transform(result, parent: parent, context: context)
    }

    // PreferVoidReturn — replaces `-> ()` with `-> Void` in closure
    // signatures. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Types/PreferVoidReturn.swift`.
    // Helpers `hasNonWhitespaceTrivia` and `makeVoidIdentifierType` live in
    // `Rewrites/Exprs/FunctionType.swift`.
    if context.shouldFormat(PreferVoidReturn.self, node: Syntax(result)) {
        result = applyPreferVoidReturnToClosureSignature(result, context: context)
    }

    return result
}

private func applyPreferVoidReturnToClosureSignature(
    _ node: ClosureSignatureSyntax,
    context: Context
) -> ClosureSignatureSyntax {
    // Diagnostic emitted in `PreferVoidReturn.willEnter(_:context:)` against
    // the pre-traversal node so finding locations come from the original tree.
    guard let returnClause = node.returnClause,
          let returnType = returnClause.type.as(TupleTypeSyntax.self),
          returnType.elements.isEmpty
    else { return node }

    if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
        || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading)
    {
        return node
    }

    let voidKeyword = makeVoidIdentifierType(toReplace: returnType)
    var newReturnClause = returnClause
    newReturnClause.type = TypeSyntax(voidKeyword)

    var result = node
    result.returnClause = newReturnClause
    return result
}

extension Finding.Message {
    fileprivate static let returnVoidClosure: Finding.Message = "replace '()' with 'Void'"
}
