import SwiftSyntax

/// Flag the pre-`Transferable` drag API.
///
/// `.onDrag` builds an `NSItemProvider` , which carries an untyped payload behind a type identifier
/// string. `.draggable` takes a value whose type conforms to `Transferable` , so the compiler
/// checks the payload and the same conformance also serves copy, paste and share.
///
/// Lint: A call to `.onDrag` , or a reference to `NSItemProvider` , raises a warning.
final class UseDraggableNotOnDrag: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "onDrag"
        {
            diagnose(.onDrag, on: member.declName)
        }
        return .visitChildren
    }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        flagItemProvider(node.name)
        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        flagItemProvider(node.baseName)
        return .visitChildren
    }

    private func flagItemProvider(_ token: TokenSyntax) {
        guard token.text == "NSItemProvider" else { return }
        diagnose(.itemProvider, on: token)
    }
}

fileprivate extension Finding.Message {
    static let onDrag: Finding.Message =
        "'.onDrag' hands SwiftUI an 'NSItemProvider' — conform the payload to 'Transferable' and use '.draggable'"
    static let itemProvider: Finding.Message =
        "'NSItemProvider' predates 'Transferable' — conform the payload type to 'Transferable' and use '.draggable'"
}
