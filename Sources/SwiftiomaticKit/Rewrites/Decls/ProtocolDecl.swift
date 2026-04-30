import SwiftSyntax

/// Compact-pipeline merge of all `ProtocolDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteProtocolDecl(
    _ node: ProtocolDeclSyntax,
    parent: Syntax?,
    context: Context
) -> ProtocolDeclSyntax {
    var result = node

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )
    context.applyRewrite(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, transform: ModifiersOnSameLine.transform
    )
    context.applyRewrite(
        RedundantAccessControl.self, to: &result,
        parent: parent, transform: RedundantAccessControl.transform
    )
    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    // PreferAnyObject — replaces `class` keyword with `AnyObject` in
    // class-constrained protocol inheritance. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Types/PreferAnyObject.swift`.
    if context.shouldRewrite(PreferAnyObject.self, at: Syntax(result)) {
        result = applyPreferAnyObject(result, context: context)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    context.applyRewrite(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, transform: WrapMultilineStatementBraces.transform
    )

    return result
}

private func applyPreferAnyObject(
    _ node: ProtocolDeclSyntax,
    context: Context
) -> ProtocolDeclSyntax {
    guard let inheritanceClause = node.inheritanceClause else { return node }

    var foundViolation = false
    let newInheritedTypes = inheritanceClause.inheritedTypes.map {
        inherited -> InheritedTypeSyntax in
        guard let classRestriction = inherited.type.as(ClassRestrictionTypeSyntax.self) else {
            return inherited
        }

        foundViolation = true
        PreferAnyObject.diagnose(
            .preferAnyObject,
            on: classRestriction.classKeyword,
            context: context
        )

        let anyObjectType = IdentifierTypeSyntax(
            name: .identifier(
                "AnyObject",
                leadingTrivia: classRestriction.classKeyword.leadingTrivia,
                trailingTrivia: classRestriction.classKeyword.trailingTrivia
            )
        )
        return inherited.with(\.type, TypeSyntax(anyObjectType))
    }

    guard foundViolation else { return node }

    let newClause = inheritanceClause.with(
        \.inheritedTypes,
        InheritedTypeListSyntax(newInheritedTypes)
    )
    return node.with(\.inheritanceClause, newClause)
}

extension Finding.Message {
    fileprivate static let preferAnyObject: Finding.Message =
        "use 'AnyObject' instead of 'class' for class-constrained protocols"
}
