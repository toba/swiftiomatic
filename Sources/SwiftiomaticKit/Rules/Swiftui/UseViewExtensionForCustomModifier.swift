import SwiftSyntax

/// Flag `.modifier(CustomModifier(...))` at a call site.
///
/// A call site that names the `ViewModifier` type depends on how the modifier is built. A `View`
/// extension method, such as `.draggableRow(...)` , gives the modifier a fluent name that reads
/// like the SwiftUI modifiers. The type can then become `private` , and its initializer can change
/// without an edit at each call site.
///
/// The rule does not report the `.modifier(...)` call inside a `View` extension, because that call
/// is the wrapper that the rule asks for. It reports only an argument that constructs a type by
/// name. A stored or conditional modifier value is not reported.
///
/// Lint: A `.modifier(_:)` call receives an initializer call of a named type, outside a `View`
/// extension.
final class UseViewExtensionForCustomModifier: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "modifier",
            let argument = node.arguments.firstAndOnly,
            argument.label == nil,
            let construction = argument.expression.as(FunctionCallExprSyntax.self),
            let typeName = construction.constructedTypeName,
            !Self.isInsideViewExtension(node) else { return .visitChildren }
        diagnose(.useViewExtension(typeName), on: member.declName)
        return .visitChildren
    }

    /// Whether `node` is inside a member of `extension View`
    private static func isInsideViewExtension(_ node: some SyntaxProtocol) -> Bool {
        var current = node.parent

        while let cur = current {
            if let ext = cur.as(ExtensionDeclSyntax.self) {
                let name = ext.extendedType.trimmedDescription
                return name == "View" || name == "SwiftUI.View"
            }
            current = cur.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static func useViewExtension(_ type: String) -> Finding.Message {
        """
        '.modifier(\(type)(...))' exposes the modifier type at the call site. Add a 'View' \
        extension method that applies it, and call that method
        """
    }
}
