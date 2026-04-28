import SwiftSyntax

/// Compact-pipeline merge of all `ProtocolDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteProtocolDecl(
    _ node: ProtocolDeclSyntax,
    context: Context
) -> ProtocolDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(ProtocolDeclSyntax.self) {
            result = next
        }
    }

    // PreferAnyObject — replaces `class` keyword with `AnyObject` in
    // class-constrained protocol inheritance. Inlined from
    // `Sources/SwiftiomaticKit/Rules/Types/PreferAnyObject.swift`.
    if context.shouldFormat(PreferAnyObject.self, node: Syntax(result)) {
        result = applyPreferAnyObject(result, context: context)
    }

    // WrapMultilineStatementBraces — unported. Audit-only.
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

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
