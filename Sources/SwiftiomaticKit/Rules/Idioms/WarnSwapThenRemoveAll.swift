import SwiftSyntax

/// Lint the `swap(&a, &b); a.removeAll(…)` (or `b.removeAll(…)` ) pattern. It almost always
/// indicates a hand-rolled alternating-buffer parser that loses `Array` / `Data` CoW guarantees and
/// is brittle when refactored.
final class WarnSwapThenRemoveAll: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        let items = Array(node)
        guard items.count >= 2 else { return .visitChildren }

        for i in 0..<items.count - 1 {
            guard let swapCall = swapInOutCall(items[i]),
                  let (a, b) = swappedNames(swapCall),
                  let removalReceiver = removeAllReceiverName(items[i + 1]),
                  removalReceiver == a || removalReceiver == b else { continue }
            diagnose(.swapThenRemoveAll(a: a, b: b, removed: removalReceiver), on: items[i + 1])
        }
        return .visitChildren
    }

    private func swapInOutCall(_ item: CodeBlockItemSyntax) -> FunctionCallExprSyntax? {
        guard let expr = item.item.as(FunctionCallExprSyntax.self),
              let ident = expr.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "swap",
              expr.arguments.count == 2 else { return nil }
        return expr
    }

    private func swappedNames(_ call: FunctionCallExprSyntax) -> (String, String)? {
        let args = Array(call.arguments)
        guard let aName = inoutIdentifier(args[0].expression),
              let bName = inoutIdentifier(args[1].expression) else { return nil }
        return (aName, bName)
    }

    private func inoutIdentifier(_ expr: ExprSyntax) -> String? {
        guard let inOut = expr.as(InOutExprSyntax.self),
              let ident = inOut.expression.as(DeclReferenceExprSyntax.self) else { return nil }
        return ident.baseName.text
    }

    private func removeAllReceiverName(_ item: CodeBlockItemSyntax) -> String? {
        guard let call = item.item.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "removeAll",
              let receiver = member.base?.as(DeclReferenceExprSyntax.self) else { return nil }
        return receiver.baseName.text
    }
}

fileprivate extension Finding.Message {
    static func swapThenRemoveAll(a: String, b: String, removed: String) -> Finding.Message {
        "'swap(&\(a), &\(b))' followed by '\(removed).removeAll' is the alternating-buffer pattern — fragile; consider an explicit double-buffer or 'reserveCapacity' on a single buffer"
    }
}
