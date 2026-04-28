import SwiftSyntax

/// Compact-pipeline merge of all `FunctionTypeSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
func rewriteFunctionType(
    _ node: FunctionTypeSyntax,
    parent: Syntax?,
    context: Context
) -> FunctionTypeSyntax {
    var result = node
    applyRule(
        RedundantTypedThrows.self, to: &result,
        parent: parent, context: context,
        transform: RedundantTypedThrows.transform
    )

    // PreferVoidReturn — replaces `-> ()` with `-> Void` in function-type
    // signatures. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Types/PreferVoidReturn.swift`.
    if context.shouldFormat(PreferVoidReturn.self, node: Syntax(result)) {
        result = applyPreferVoidReturn(result, context: context)
    }

    return result
}

private func applyPreferVoidReturn(
    _ node: FunctionTypeSyntax,
    context: Context
) -> FunctionTypeSyntax {
    guard let returnType = node.returnClause.type.as(TupleTypeSyntax.self),
          returnType.elements.isEmpty
    else { return node }

    PreferVoidReturn.diagnose(.returnVoid, on: returnType, context: context)

    if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
        || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading)
    {
        return node
    }

    let voidKeyword = makeVoidIdentifierType(toReplace: returnType)
    var rewritten = node
    rewritten.returnClause.type = TypeSyntax(voidKeyword)
    return rewritten
}

func hasNonWhitespaceTrivia(_ token: TokenSyntax, at position: TriviaPosition) -> Bool {
    for piece in position == .leading ? token.leadingTrivia : token.trailingTrivia {
        switch piece {
            case .blockComment, .docBlockComment, .docLineComment, .unexpectedText, .lineComment:
                return true
            default: break
        }
    }
    return false
}

func makeVoidIdentifierType(toReplace node: TupleTypeSyntax) -> IdentifierTypeSyntax {
    IdentifierTypeSyntax(
        name: TokenSyntax.identifier(
            "Void",
            leadingTrivia: node.firstToken(viewMode: .sourceAccurate)?.leadingTrivia ?? [],
            trailingTrivia: node.lastToken(viewMode: .sourceAccurate)?.trailingTrivia ?? []
        ),
        genericArgumentClause: nil
    )
}

extension Finding.Message {
    fileprivate static let returnVoid: Finding.Message = "replace '()' with 'Void'"
}
