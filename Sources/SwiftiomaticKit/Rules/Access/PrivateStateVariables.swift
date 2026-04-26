import SwiftSyntax

/// Add `private` to `@State` properties without explicit access control.
///
/// SwiftUI `@State` and `@StateObject` properties should be `private` because they are
/// owned by the view and should not be set from outside. If no access control modifier is
/// present, `private` is added. Existing access modifiers (including `private(set)`) and
/// `@Previewable` properties are left unchanged.
///
/// Lint: A `@State` or `@StateObject` property without access control raises a warning.
///
/// Rewrite: The `private` modifier is added before the binding keyword.
final class PrivateStateVariables: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .access }
    override static var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

    /// Attribute names that trigger the rule.
    private static let stateAttributes: Set<String> = ["State", "StateObject"]

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        // Must have @State or @StateObject attribute
        guard hasStateAttribute(node) else { return DeclSyntax(node) }

        // Skip if already has access control
        guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }

        // Skip @Previewable properties
        guard !hasAttribute(named: "Previewable", on: node) else { return DeclSyntax(node) }

        diagnose(.addPrivateToStateProperty, on: node.bindingSpecifier)

        var result = node
        var privateModifier = DeclModifierSyntax(
            name: .keyword(.private, trailingTrivia: .space)
        )

        if result.modifiers.isEmpty {
            // Transfer leading trivia from binding specifier to the new modifier
            privateModifier.leadingTrivia = result.bindingSpecifier.leadingTrivia
            result.bindingSpecifier.leadingTrivia = []
        }

        result.modifiers.append(privateModifier)
        return DeclSyntax(result)
    }

    private func hasStateAttribute(_ node: VariableDeclSyntax) -> Bool {
        node.attributes.contains { element in
            guard let attr = element.as(AttributeSyntax.self),
                let name = attr.attributeName.as(IdentifierTypeSyntax.self)
            else { return false }
            return Self.stateAttributes.contains(name.name.text)
        }
    }

    private func hasAttribute(named name: String, on node: VariableDeclSyntax) -> Bool {
        node.attributes.contains { element in
            guard let attr = element.as(AttributeSyntax.self),
                let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)
            else { return false }
            return attrName.name.text == name
        }
    }
}

extension Finding.Message {
    fileprivate static let addPrivateToStateProperty: Finding.Message =
        "add 'private' to this @State property"
}
