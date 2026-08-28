import SwiftSyntax

/// Warn on `ForEach` whose receiver is an integer-index sequence (`<expr>.indices`, `a..<b`,
/// `a...b`, `Range(...)`). Row identity becomes positional, so insertions and removals shift every
/// following row's id and SwiftUI redraws (and resets `@State`) past the mutation point. Prefer
/// `ForEach(Array(<collection>.enumerated()), id: \.element.id)`.
///
/// Orthogonal to `FlagForEachIDSelfInView`: that rule keys on the `id:` axis (`\.self` is fragile
/// on element collections); this rule keys on the receiver axis and ignores the `id:` argument
/// entirely. The two rules are designed not to co-fire — the integer-indexed case is exempted from
/// `FlagForEachIDSelfInView` and owned here.
final class FlagForEachOverIndices: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
            ident.baseName.text == "ForEach" else { return .visitChildren }

        guard let firstArg = node.arguments.first, firstArg.label == nil
        else { return .visitChildren }

        if isIntegerIndexedReceiver(firstArg.expression) {
            diagnose(.indicesReceiver, on: firstArg.expression)
        }
        return .visitChildren
    }

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
}

fileprivate extension Finding.Message {
    static let indicesReceiver: Finding.Message =
        "'ForEach' over indices loses row identity on insert/remove — use 'ForEach(Array(<collection>.enumerated()), id: \\.element.id)'"
}
