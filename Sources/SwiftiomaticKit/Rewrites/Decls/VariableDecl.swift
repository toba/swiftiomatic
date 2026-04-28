import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `VariableDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteVariableDecl(
    _ node: VariableDeclSyntax,
    parent: Syntax?,
    context: Context
) -> VariableDeclSyntax {
    var result = node

    applyRule(
        AvoidNoneName.self, to: &result,
        parent: parent, context: context,
        transform: AvoidNoneName.transform
    )

    applyRule(
        DocCommentsPrecedeModifiers.self, to: &result,
        parent: parent, context: context,
        transform: DocCommentsPrecedeModifiers.transform
    )

    applyRule(
        ModifierOrder.self, to: &result,
        parent: parent, context: context,
        transform: ModifierOrder.transform
    )

    applyRule(
        ModifiersOnSameLine.self, to: &result,
        parent: parent, context: context,
        transform: ModifiersOnSameLine.transform
    )

    applyRule(
        PrivateStateVariables.self, to: &result,
        parent: parent, context: context,
        transform: PrivateStateVariables.transform
    )

    applyRule(
        RedundantAccessControl.self, to: &result,
        parent: parent, context: context,
        transform: RedundantAccessControl.transform
    )

    applyRule(
        RedundantNilInit.self, to: &result,
        parent: parent, context: context,
        transform: RedundantNilInit.transform
    )

    applyRule(
        RedundantObjc.self, to: &result,
        parent: parent, context: context,
        transform: RedundantObjc.transform
    )

    applyRule(
        RedundantPattern.self, to: &result,
        parent: parent, context: context,
        transform: RedundantPattern.transform
    )

    applyRule(
        RedundantSetterACL.self, to: &result,
        parent: parent, context: context,
        transform: RedundantSetterACL.transform
    )

    applyRule(
        RedundantType.self, to: &result,
        parent: parent, context: context,
        transform: RedundantType.transform
    )

    applyRule(
        RedundantViewBuilder.self, to: &result,
        parent: parent, context: context,
        transform: RedundantViewBuilder.transform
    )

    applyRule(
        TripleSlashDocComments.self, to: &result,
        parent: parent, context: context,
        transform: TripleSlashDocComments.transform
    )

    // StrongOutlets — removes `weak` from `@IBOutlet` properties (preserves
    // it for delegate/dataSource outlets). Inlined from
    // `Sources/SwiftiomaticKit/Rules/Memory/StrongOutlets.swift`.
    if context.shouldFormat(StrongOutlets.self, node: Syntax(result)) {
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
