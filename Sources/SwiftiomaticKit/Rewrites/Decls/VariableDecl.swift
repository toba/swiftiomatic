import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `VariableDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldRewrite(<RuleType>.self, at:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteVariableDecl(
    _ node: VariableDeclSyntax,
    parent: Syntax?,
    context: Context
) -> VariableDeclSyntax {
    var result = node

    context.applyRewrite(
        AvoidNoneName.self, to: &result,
        parent: parent, transform: AvoidNoneName.transform
    )

    context.applyRewrite(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, transform: DocCommentsPrecedeModifiers.transform
    )

    context.applyRewrite(
        ModifierOrder.self, to: &result,
        parent: parent, transform: ModifierOrder.transform
    )

    context.applyRewrite(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, transform: ModifiersOnSameLine.transform
    )

    context.applyRewrite(
        PrivateStateVariables.self, to: &result,
        parent: parent, transform: PrivateStateVariables.transform
    )

    context.applyRewrite(
        RedundantAccessControl.self, to: &result,
        parent: parent, transform: RedundantAccessControl.transform
    )

    context.applyRewrite(
        RedundantNilInit.self, to: &result,
        parent: parent, transform: RedundantNilInit.transform
    )

    context.applyRewrite(
        RedundantObjc.self, to: &result,
        parent: parent, transform: RedundantObjc.transform
    )

    context.applyRewrite(
        RedundantPattern.self, to: &result,
        parent: parent, transform: RedundantPattern.transform
    )

    context.applyRewrite(
        RedundantSetterACL.self, to: &result,
        parent: parent, transform: RedundantSetterACL.transform
    )

    context.applyRewrite(
        RedundantType.self, to: &result,
        parent: parent, transform: RedundantType.transform
    )

    context.applyRewrite(
        RedundantViewBuilder.self, to: &result,
        parent: parent, transform: RedundantViewBuilder.transform
    )

    context.applyRewrite(
        TripleSlashDocComments.self, to: &result,
        parent: parent, transform: TripleSlashDocComments.transform
    )

    // StrongOutlets — removes `weak` from `@IBOutlet` properties (preserves
    // it for delegate/dataSource outlets). Inlined from
    // `Sources/SwiftiomaticKit/Rules/Memory/StrongOutlets.swift`.
    if context.shouldRewrite(StrongOutlets.self, at: Syntax(result)) {
        result = applyStrongOutlets(result, context: context)
    }

    return result
}

private func applyStrongOutlets(
    _ node: VariableDeclSyntax,
    context: Context
) -> VariableDeclSyntax {
    guard hasIBOutletAttribute(node), node.modifiers.contains(.weak) else {
        return node
    }

    if let name = node.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
        let lowercased = name.lowercased()
        if lowercased.hasSuffix("delegate") || lowercased.hasSuffix("datasource") {
            return node
        }
    }

    guard let weakModifier = node.modifiers.first(where: {
        $0.name.tokenKind == .keyword(.weak)
    }) else {
        return node
    }

    StrongOutlets.diagnose(.removeWeakFromOutlet, on: weakModifier.name, context: context)

    var result = node
    let weakIsFirst = result.modifiers.first?.name.tokenKind == .keyword(.weak)
    let savedLeadingTrivia = weakIsFirst ? weakModifier.leadingTrivia : Trivia()

    result.modifiers.remove(anyOf: [.weak])

    if weakIsFirst {
        if var firstModifier = result.modifiers.first {
            firstModifier.leadingTrivia = savedLeadingTrivia
            result.modifiers[result.modifiers.startIndex] = firstModifier
        } else {
            result.bindingSpecifier.leadingTrivia = savedLeadingTrivia
        }
    }

    return result
}

private func hasIBOutletAttribute(_ node: VariableDeclSyntax) -> Bool {
    node.attributes.contains { element in
        if let attr = element.as(AttributeSyntax.self),
           let name = attr.attributeName.as(IdentifierTypeSyntax.self)
        {
            name.name.text == "IBOutlet"
        } else {
            false
        }
    }
}

extension Finding.Message {
    fileprivate static let removeWeakFromOutlet: Finding.Message =
        "remove 'weak' from @IBOutlet property"
}
