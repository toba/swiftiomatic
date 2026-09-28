import SwiftSyntax

/// Add `private` to view-owned state properties without explicit access control.
///
/// SwiftUI owns the storage of `@State`, `@StateObject`, `@AppStorage`, `@SceneStorage`,
/// `@FocusState` and `@GestureState` properties. The view installs the storage, so a value that a
/// parent passes through the memberwise initializer only seeds it once and is then ignored. Make
/// these properties `private` so that no caller can pass a value that has no effect. In Xcode 27
/// and later, `@State` also evaluates its initial value only once, when SwiftUI sets up the
/// storage, but only when the property is `private`.
///
/// An `@Environment` or `@EnvironmentObject` property reads a value from the environment of the
/// view. The value is local to the view too, so the property is `private` for the same reason.
///
/// ```swift
/// @State private var isExpanded = false
/// ```
///
/// Keep an input that the parent supplies, such as a plain `let`, `@Binding`, `@Bindable` or
/// `@ObservedObject` property, without `private`. A `private` input makes the memberwise
/// initializer `private` too.
///
/// If no access control modifier is present, `private` is added. The rule leaves a property that
/// has an access modifier unchanged. This includes `private(set)` and `fileprivate`, which do not
/// make the property private. The rewrite cannot tell whether code outside the type reads such a
/// property, so change it by hand when nothing does. The rule also leaves `@Previewable` properties
/// unchanged. The rule applies only to a stored property of a type that conforms to `View` or
/// `ViewModifier` in the same file. Another type, such as an `@Observable` class with an
/// `@AppStorage` property, is left unchanged, because code outside the type reads the property.
///
/// Lint: A `@State` , `@StateObject` , `@AppStorage` , `@SceneStorage` , `@FocusState` ,
/// `@GestureState` , `@Environment` or `@EnvironmentObject` property of a view type without access
/// control raises a warning.
///
/// Rewrite: The `private` modifier is added before the binding keyword.
final class MakeStateVarsPrivate: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 380

    override static var group: ConfigurationGroup? { .access }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }
    override class var guidance: GuidanceLevel { .must }

    static func transform(
        _ node: VariableDeclSyntax,
        original: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        // Must have a view-owned state attribute, on a member of a view type. Another type, such as
        // an `@Observable` settings class with an `@AppStorage` property, reads the property from
        // outside, so `private` would break the build.
        guard let wrapper = stateAttribute(of: node),
              context.viewEntry(forMember: original) != nil else { return DeclSyntax(node) }

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

    /// Wrappers that read a value from the environment of the view. The value is local to the view,
    /// like its state.
    private static let environmentWrappers: Set<String> = ["Environment", "EnvironmentObject"]

    /// The name of the first view-owned state wrapper on `node` , if any
    private static func stateAttribute(of node: VariableDeclSyntax) -> String? {
        node.attributes.lazy.compactMap { element -> String? in
            guard let attr = element.as(AttributeSyntax.self),
                  let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                  VariableDeclSyntax.installedStorageWrappers.contains(name)
                      || environmentWrappers.contains(name) else { return nil }
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
