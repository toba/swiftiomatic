import SwiftSyntax

/// Remove nil-coalescing where the right-hand side is `nil` .
///
/// `x ?? nil` is identical in value and type to `x` itself.
///
/// Lint: A finding is raised when `??` has a `nil` literal on the right-hand side.
///
/// Rewrite: The `??` operator and the `nil` right-hand side are removed.
final class DropRedundantNilCoalescing: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ node: InfixOperatorExprSyntax,
        original: InfixOperatorExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard let op = node.operator.as(BinaryOperatorExprSyntax.self),
              op.operator.tokenKind == .binaryOperator("??"),
              node.rightOperand.is(NilLiteralExprSyntax.self) else { return ExprSyntax(node) }

        // Without type info we can't tell whether the LHS is a single or double
        // optional. `?? nil` is a no-op for `T?` but flattens `T??` to `T?` — and
        // stripping it in the latter case breaks compilation. Conservatively skip
        // any LHS that involves a function call, subscript, or `try?`, where the
        // result type plausibly comes from a signature we can't see.
        if lhsMayProduceDoubleOptional(node.leftOperand) {
            return ExprSyntax(node)
        }

        // Anchor the finding to the `??` token in the *original* input. `node` is the
        // post-children-rewrite subtree, which may be detached from the source-file root —
        // computing a `SourceLocation` on a detached node yields the wrong line/column,
        // because the `SourceLocationConverter` is built from the original source bytes
        // and the operator's offset within a detached subtree starts near 0.
        let originalOperator = original.operator.as(BinaryOperatorExprSyntax.self)?.operator
        Self.diagnose(.removeRedundantNilCoalescing, on: originalOperator, context: context)

        // Strip the operator's leading space (which was the space between LHS and `??` ) by
        // clearing the LHS's trailing trivia.
        var newLeft = node.leftOperand
        newLeft.trailingTrivia = []
        // Preserve any trailing trivia that was on the RHS `nil` (e.g. line break).
        newLeft.trailingTrivia += node.rightOperand.trailingTrivia
        return newLeft
    }
}

/// Returns true when the LHS contains a function call, subscript, or `try?`,
/// any of which may yield a doubly-optional value that `?? nil` is flattening.
private func lhsMayProduceDoubleOptional(_ expr: ExprSyntax) -> Bool {
    final class Walker: SyntaxAnyVisitor {
        var found = false
        override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
            if found { return .skipChildren }
            if node.is(FunctionCallExprSyntax.self)
                || node.is(SubscriptCallExprSyntax.self)
            {
                found = true
                return .skipChildren
            }
            if let tryExpr = node.as(TryExprSyntax.self),
               tryExpr.questionOrExclamationMark?.tokenKind == .postfixQuestionMark
            {
                found = true
                return .skipChildren
            }
            return .visitChildren
        }
    }
    let walker = Walker(viewMode: .sourceAccurate)
    walker.walk(expr)
    return walker.found
}

fileprivate extension Finding.Message {
    static let removeRedundantNilCoalescing: Finding.Message =
        "remove redundant '?? nil'; the value is unchanged"
}
