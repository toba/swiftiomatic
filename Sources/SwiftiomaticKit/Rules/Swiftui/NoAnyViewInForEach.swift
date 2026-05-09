import SwiftSyntax

/// Flag `AnyView(...)` constructed inside a `ForEach` body. Type-erasing each row defeats
/// SwiftUI's structural identity, forces extra invalidation, and almost always indicates a
/// missing `@ViewBuilder` helper or a `Group { ... }` with branches. Move the branching into
/// a `@ViewBuilder` function or use `if / switch` directly inside the closure.
final class NoAnyViewInForEach: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "AnyView" else { return .visitChildren }
        if isInsideForEachClosure(node) {
            diagnose(.anyViewInForEach, on: node.calledExpression)
        }
        return .visitChildren
    }

    private func isInsideForEachClosure(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax? = Syntax(node).parent
        while let cur = current {
            if let call = cur.as(FunctionCallExprSyntax.self),
               let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
               callee.baseName.text == "ForEach"
            {
                let pos = node.position
                if let trailing = call.trailingClosure,
                   pos >= trailing.position, pos < trailing.endPosition
                {
                    return true
                }
                for additional in call.additionalTrailingClosures {
                    if pos >= additional.position, pos < additional.endPosition {
                        return true
                    }
                }
                return false
            }
            current = cur.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let anyViewInForEach: Finding.Message =
        "'AnyView' inside 'ForEach' erases row identity and forces extra invalidation — extract a '@ViewBuilder' helper or use 'Group' with 'if'/'switch'"
}
