import SwiftSyntax

/// Prefer `allSatisfy` or `contains` over `reduce(true)` / `reduce(false)` .
///
/// `reduce(true) { $0 && ... }` and `reduce(false) { $0 || ... }` are spellings of `allSatisfy` and
/// `contains` that don't short-circuit. The dedicated methods stop as soon as the answer is
/// determined.
///
/// Lint:
/// - `xs.reduce(true) { ... }` / `xs.reduce(into: true) { ... }` → suggest `allSatisfy`
/// - `xs.reduce(false) { ... }` / `xs.reduce(into: false) { ... }` → suggest `contains`
final class PreferAllSatisfy: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .collections }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "reduce",
              let firstArgument = node.arguments.first,
              // Either no label ( `reduce(true, ...)` ) or `into:` ( `reduce(into: true, ...)` ).
              (firstArgument.label?.text ?? "into") == "into",
              let bool = firstArgument.expression.as(BooleanLiteralExprSyntax.self) else {
            return .visitChildren
        }

        let isTrue = bool.literal.tokenKind == .keyword(.true)
        diagnose(.preferAllSatisfy(isTrue: isTrue), on: member.declName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func preferAllSatisfy(isTrue: Bool) -> Finding.Message {
        isTrue
            ? "prefer 'allSatisfy' over 'reduce(true)'"
            : "prefer 'contains' over 'reduce(false)'"
    }
}
