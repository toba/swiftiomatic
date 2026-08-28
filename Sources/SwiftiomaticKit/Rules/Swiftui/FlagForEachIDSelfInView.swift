import SwiftSyntax

/// Warn on `ForEach(_, id: \.self)` . SwiftUI uses `id` to diff views across updates; using
/// `\.self` requires the element to be both `Hashable` and stable (its hash must not change when
/// other state changes). Prefer making the element `Identifiable` .
final class FlagForEachIDSelfInView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
            ident.baseName.text == "ForEach" else { return .visitChildren }

        if let firstArg = node.arguments.first,
           firstArg.label == nil,
           isIntegerIndexedReceiver(firstArg.expression) { return .visitChildren }

        for arg in node.arguments where arg.label?.text == "id" {
            if isKeyPathSelf(arg.expression) { diagnose(.idSelfFragile, on: arg.expression) }
        }
        return .visitChildren
    }

    /// `<expr>.indices`, or a `Range`/`ClosedRange` literal (`a..<b`, `a...b`), or `Range(...)`.
    /// For these, `Int` is the element type and `\.self` is the only valid id.
    private func isIntegerIndexedReceiver(_ expr: ExprSyntax) -> Bool {
        if let member = expr.as(MemberAccessExprSyntax.self),
           member.declName.baseName.text == "indices" { return true }

        if let infix = expr.as(InfixOperatorExprSyntax.self),
           let op = infix.operator.as(BinaryOperatorExprSyntax.self)
        {
            let text = op.operator.text
            if text == "..<" || text == "..." { return true }
        }
        if let seq = expr.as(SequenceExprSyntax.self) {
            for element in seq.elements {
                if let op = element.as(BinaryOperatorExprSyntax.self) {
                    let text = op.operator.text
                    if text == "..<" || text == "..." { return true }
                }
            }
        }
        if let call = expr.as(FunctionCallExprSyntax.self),
           let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
           callee.baseName.text == "Range" { return true }
        return false
    }

    private func isKeyPathSelf(_ expr: ExprSyntax) -> Bool {
        guard let kp = expr.as(KeyPathExprSyntax.self),
              kp.components.count == 1,
              let only = kp.components.first else { return false }
        if let property = only.component.as(KeyPathPropertyComponentSyntax.self),
            property.declName.baseName.tokenKind == .keyword(.self) { return true }
        return false
    }
}

fileprivate extension Finding.Message {
    static let idSelfFragile: Finding.Message =
        "'id: \\.self' is fragile — make the element 'Identifiable' or supply a stable id key path"
}
