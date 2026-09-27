import SwiftSyntax

/// Flag a function whose main path sits inside a trailing `if` with no `else`.
///
/// When the last statement of a function is an `if` with no `else`, the function falls through when
/// the condition is false. The work of the function then sits one level deeper than it has to. A
/// `guard` with the inverse exit states the precondition first and keeps the main path at the top
/// level of the body:
///
/// ```swift
/// func draw(_ context: CGContext) {
///     guard let color = localBackgroundColor else { return }
///     context.setFillColor(color.cgColor)
///     ...
/// }
/// ```
///
/// The rule checks the bodies of functions, initializers, deinitializers and accessors. It stays
/// silent for an `if` body with fewer than three statements, because a short conditional step reads
/// as clearly as a `guard`. `UseEarlyExits` covers the `if ... else { return }` form.
///
/// Lint: A trailing `if` with no `else` and a body of three or more statements raises a warning.
final class UseGuardForMainPath: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }
    override class var guidance: GuidanceLevel { .consider }

    /// The smallest number of statements in the `if` body that the rule reports.
    private static let minimumBodyStatements = 3

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.body)
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.body)
        return .visitChildren
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.body)
        return .visitChildren
    }

    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.body)
        return .visitChildren
    }

    private func check(_ body: CodeBlockSyntax?) {
        guard let last = body?.statements.last,
              let ifExpr = last.item.as(ExpressionStmtSyntax.self)?.expression.as(IfExprSyntax.self)
                  ?? last.item.as(IfExprSyntax.self),
              ifExpr.elseBody == nil,
              ifExpr.body.statements.count >= Self.minimumBodyStatements else { return }
        diagnose(.useGuardForMainPath, on: ifExpr.ifKeyword)
    }
}

fileprivate extension Finding.Message {
    static let useGuardForMainPath: Finding.Message =
        "the main path sits inside this trailing 'if'; use 'guard ... else { return }' and unindent the body"
}
