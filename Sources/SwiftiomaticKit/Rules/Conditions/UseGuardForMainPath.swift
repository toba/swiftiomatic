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
/// The rule also reports the `if` when a lone `return` follows it and that `return` has no value or
/// a literal value such as `nil` or `false`. The `guard` then repeats that `return` in its `else`.
/// A `return` with a computed value stays silent, because the `guard` would have to repeat the
/// computation.
///
/// The rule checks the bodies of functions, initializers, deinitializers and accessors. It stays
/// silent for an `if` body with fewer than three statements, because a short conditional step reads
/// as clearly as a `guard`. `UseEarlyExits` covers the `if ... else { return }` form.
///
/// The rule does not report an `if` that has an `else`. Keep the `if` / `else` when both branches
/// do substantial, different work, because neither branch is then an early exit.
///
/// Lint: A trailing `if` with no `else` and a body of three or more statements raises a warning.
/// A lone fallback `return` after the `if` does not change this.
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
        guard let statements = body?.statements, var candidate = statements.last else { return }
        if let fallback = candidate.item.as(ReturnStmtSyntax.self), Self.isFallbackReturn(fallback),
           statements.count > 1
        {
            candidate = statements[statements.index(before: statements.index(before: statements.endIndex))]
        }
        guard let ifExpr = candidate.expression?.as(IfExprSyntax.self),
              ifExpr.elseBody == nil,
              ifExpr.body.statements.count >= Self.minimumBodyStatements else { return }
        diagnose(.useGuardForMainPath, on: ifExpr.ifKeyword)
    }

    /// Whether `node` returns nothing or a literal, so a `guard` can repeat it in its `else`.
    private static func isFallbackReturn(_ node: ReturnStmtSyntax) -> Bool {
        guard let expression = node.expression else { return true }
        if let array = expression.as(ArrayExprSyntax.self) { return array.elements.isEmpty }
        if let dictionary = expression.as(DictionaryExprSyntax.self) {
            return dictionary.content.is(TokenSyntax.self)
        }
        return expression.is(NilLiteralExprSyntax.self)
            || expression.is(BooleanLiteralExprSyntax.self)
            || expression.is(IntegerLiteralExprSyntax.self)
            || expression.is(FloatLiteralExprSyntax.self)
            || expression.is(StringLiteralExprSyntax.self)
    }
}

fileprivate extension Finding.Message {
    static let useGuardForMainPath: Finding.Message =
        "the main path sits inside this trailing 'if'; use 'guard ... else { return }' and unindent the body"
}
