import SwiftSyntax

/// Add `private` to view-owned state properties without explicit access control.
///
/// SwiftUI owns the storage of `@State` , `@StateObject` , `@AppStorage` , `@SceneStorage` ,
/// `@FocusState` and `@GestureState` properties. The view installs the storage, so a value that a
/// parent passes through the memberwise initializer only seeds it once and is then ignored. Make
/// these properties `private` so that no caller can pass a value that has no effect.
///
/// If no access control modifier is present, `private` is added. Existing access modifiers
/// (including `private(set)` ) and `@Previewable` properties are left unchanged.
///
/// Lint: A `@State` , `@StateObject` , `@AppStorage` , `@SceneStorage` , `@FocusState` or
/// `@GestureState` property without access control raises a warning.
///
/// Rewrite: The `private` modifier is added before the binding keyword.
final class MakeStateVarsPrivate: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 380

    override static var group: ConfigurationGroup? { .access }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
    override class var guidance: GuidanceLevel { .must }

    /// Attribute names that trigger the rule.
    private static let stateAttributes: Set<String> = [
        "State", "StateObject", "AppStorage", "SceneStorage", "FocusState", "GestureState",
    ]

    static func transform(
        _ node: VariableDeclSyntax,
        original: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        // Must have a view-owned state attribute
        guard let wrapper = stateAttribute(of: node) else { return DeclSyntax(node) }

        // Skip if already has access control
        guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }

        // Skip @Previewable properties
        guard !hasAttribute(named: "Previewable", on: node) else { return DeclSyntax(node) }

        // Diagnose against the original node. `node` is detached from the source tree once another
        // rule in the same pass rewrites a child, so its positions no longer match the file.
        Self.diagnose(
            .addPrivateToStateProperty(wrapper), on: original.bindingSpecifier, context: context)

        var result = node
        var privateModifier = DeclModifierSyntax(name: .keyword(.private, trailingTrivia: .space))

        if result.modifiers.isEmpty {
            // Transfer leading trivia from binding specifier to the new modifier
            privateModifier.leadingTrivia = result.bindingSpecifier.leadingTrivia
            result.bindingSpecifier.leadingTrivia = []
        }

        result.modifiers.append(privateModifier)
        return DeclSyntax(result)
    }

    /// The name of the first view-owned state wrapper on `node` , if any
    private static func stateAttribute(of node: VariableDeclSyntax) -> String? {
        node.attributes.lazy.compactMap { element -> String? in
            guard let attr = element.as(AttributeSyntax.self),
                  let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                  Self.stateAttributes.contains(name) else { return nil }
            return name
        }.first
    }

    private static func hasAttribute(named name: String, on node: VariableDeclSyntax) -> Bool {
        node.attributes.contains { element in
            guard let attr = element.as(AttributeSyntax.self),
                  let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)
            else { return false }
            return attrName.name.text == name
        }
    }
}

fileprivate extension Finding.Message {
    static func addPrivateToStateProperty(_ wrapper: String) -> Finding.Message {
        "add 'private' to this @\(wrapper) property"
    }
}
