import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Compact-pipeline merge of all `VariableDeclSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4c of `ddi-wtv`.
func rewriteVariableDecl(
    _ node: VariableDeclSyntax,
    context: Context
) -> VariableDeclSyntax {
    var result = node
    let parent: Syntax? = nil

    // AvoidNoneName
    if context.shouldFormat(AvoidNoneName.self, node: Syntax(result)) {
        if let next = AvoidNoneName.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // DocCommentsPrecedeModifiers
    if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(result)) {
        if let next = DocCommentsPrecedeModifiers.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // ModifierOrder
    if context.shouldFormat(ModifierOrder.self, node: Syntax(result)) {
        if let next = ModifierOrder.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // ModifiersOnSameLine
    if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(result)) {
        if let next = ModifiersOnSameLine.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // PrivateStateVariables
    if context.shouldFormat(PrivateStateVariables.self, node: Syntax(result)) {
        if let next = PrivateStateVariables.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantAccessControl
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        if let next = RedundantAccessControl.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantNilInit
    if context.shouldFormat(RedundantNilInit.self, node: Syntax(result)) {
        if let next = RedundantNilInit.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantObjc
    if context.shouldFormat(RedundantObjc.self, node: Syntax(result)) {
        if let next = RedundantObjc.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantPattern
    if context.shouldFormat(RedundantPattern.self, node: Syntax(result)) {
        if let next = RedundantPattern.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantSetterACL
    if context.shouldFormat(RedundantSetterACL.self, node: Syntax(result)) {
        if let next = RedundantSetterACL.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantType
    if context.shouldFormat(RedundantType.self, node: Syntax(result)) {
        if let next = RedundantType.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // RedundantViewBuilder
    if context.shouldFormat(RedundantViewBuilder.self, node: Syntax(result)) {
        if let next = RedundantViewBuilder.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

    // TripleSlashDocComments
    if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(result)) {
        if let next = TripleSlashDocComments.transform(
            result, parent: parent, context: context
        ).as(VariableDeclSyntax.self) {
            result = next
        }
    }

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

    StrongOutlets.diagnose(
        .removeWeakFromOutlet,
        on: node.modifiers.first(where: { $0.name.tokenKind == .keyword(.weak) })!.name,
        context: context
    )

    var result = node
    let weakIsFirst = result.modifiers.first?.name.tokenKind == .keyword(.weak)
    let savedLeadingTrivia = weakIsFirst ? result.modifiers.first!.leadingTrivia : Trivia()

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
