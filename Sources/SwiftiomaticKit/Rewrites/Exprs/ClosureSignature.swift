import SwiftSyntax

/// Compact-pipeline merge of all `ClosureSignatureSyntax` rewrites. Each
/// former rule's logic is gated on
/// `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
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
    guard let returnClause = node.returnClause,
          let returnType = returnClause.type.as(TupleTypeSyntax.self),
          returnType.elements.isEmpty
    else { return node }

    PreferVoidReturn.diagnose(.returnVoidClosure, on: returnType, context: context)

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
