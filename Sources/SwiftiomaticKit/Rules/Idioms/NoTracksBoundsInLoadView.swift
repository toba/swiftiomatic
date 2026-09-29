import SwiftSyntax

/// Flag an assignment to `tracksTextAttachmentViewBounds` inside `loadView()` .
///
/// TextKit reads `tracksTextAttachmentViewBounds` of an `NSTextAttachmentViewProvider` when it
/// creates the provider, before it calls `loadView()` . A value set in `loadView()` comes too late.
/// The layout then does not follow the bounds of the attachment view.
///
/// Set the property in the initializer of the provider.
///
/// The rule counts an assignment in a closure inside `loadView()` . It does not count an assignment
/// in a function that `loadView()` declares.
///
/// Lint: `loadView()` assigns `tracksTextAttachmentViewBounds` or
/// `self.tracksTextAttachmentViewBounds` .
final class NoTracksBoundsInLoadView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .mustNot }

    private static let propertyName = "tracksTextAttachmentViewBounds"

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.operator.is(AssignmentExprSyntax.self),
              Self.namesProperty(node.leftOperand),
              Self.isInsideLoadView(node) else { return .visitChildren }
        diagnose(.setInInitializer, on: node.leftOperand)
        return .visitChildren
    }

    /// Whether `expr` is `tracksTextAttachmentViewBounds` or `self.tracksTextAttachmentViewBounds`
    private static func namesProperty(_ expr: ExprSyntax) -> Bool {
        if let reference = expr.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == propertyName
        }
        guard let member = expr.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == propertyName,
              let base = member.base?.as(DeclReferenceExprSyntax.self) else { return false }
        return base.baseName.tokenKind == .keyword(.self)
    }

    /// Whether the innermost function that holds `node` is `loadView()` with no parameters
    private static func isInsideLoadView(_ node: some SyntaxProtocol) -> Bool {
        var current = node.parent

        while let ancestor = current {
            if let function = ancestor.as(FunctionDeclSyntax.self) {
                return function.name.text == "loadView"
                    && function.signature.parameterClause.parameters.isEmpty
            }
            // Other declarations with code end the search
            if ancestor.is(InitializerDeclSyntax.self) || ancestor.is(AccessorDeclSyntax.self)
                || ancestor.is(MemberBlockSyntax.self)
            {
                return false
            }
            current = ancestor.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let setInInitializer: Finding.Message =
        "set 'tracksTextAttachmentViewBounds' in the initializer. TextKit reads it before 'loadView()' runs"
}
