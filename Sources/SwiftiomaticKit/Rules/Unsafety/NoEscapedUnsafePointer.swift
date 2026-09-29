import SwiftSyntax

/// Flag a `withUnsafe…` closure that returns the pointer it receives.
///
/// The pointer that `withUnsafeBytes` , `withUnsafeBufferPointer` , `withUnsafePointer` and their
/// mutable forms pass to the closure is valid only inside the closure. A closure that returns the
/// pointer, or its `baseAddress` , hands the caller a dangling pointer. For example,
/// `self.bytes = source.withUnsafeBytes { $0 }` is already a lifetime bug. Do the work inside the
/// closure, or store a `Span` and state the dependency with `@_lifetime` .
///
/// The rule does not report a closure that returns a value computed from the pointer, such as
/// `$0.load(as: UInt32.self)` or `$0.count` .
///
/// Lint: A `withUnsafe…` call whose closure body is only the pointer parameter, its `baseAddress`
/// or its force-unwrapped `baseAddress` raises a warning.
final class NoEscapedUnsafePointer: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    private static let pointerScopes: Set<String> = [
        "withUnsafeBytes", "withUnsafeMutableBytes",
        "withUnsafeBufferPointer", "withUnsafeMutableBufferPointer",
        "withUnsafePointer", "withUnsafeMutablePointer",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName
            ?? node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName

        guard let name,
              Self.pointerScopes.contains(name.text),
              let closure = node.trailingClosure
                  ?? node.arguments.last?.expression.as(ClosureExprSyntax.self),
              let result = singleResult(of: closure),
              isPointer(result, parameter: parameterName(of: closure))
        else { return .visitChildren }

        diagnose(.escapedPointer(name.text), on: name)
        return .visitChildren
    }

    /// The expression that the closure body returns, when the body holds exactly one expression.
    private func singleResult(of closure: ClosureExprSyntax) -> ExprSyntax? {
        guard let item = closure.statements.firstAndOnly?.item else { return nil }
        if let expression = item.as(ExprSyntax.self) { return expression }
        return item.as(ReturnStmtSyntax.self)?.expression
    }

    /// The name of the closure's single parameter, or `$0` when the closure names none.
    private func parameterName(of closure: ClosureExprSyntax) -> String? {
        guard let clause = closure.signature?.parameterClause else { return "$0" }

        switch clause {
            case let .simpleInput(parameters):
                guard let parameter = parameters.firstAndOnly else { return nil }
                return parameter.name.text
            case let .parameterClause(clause):
                guard let parameter = clause.parameters.firstAndOnly else { return nil }
                return (parameter.secondName ?? parameter.firstName).text
        }
    }

    /// Whether `expression` is `parameter` , `parameter.baseAddress` or `parameter.baseAddress!` .
    private func isPointer(_ expression: ExprSyntax, parameter: String?) -> Bool {
        guard let parameter, parameter != "_" else { return false }

        var current = expression
        if let unwrap = current.as(ForceUnwrapExprSyntax.self) { current = unwrap.expression }

        if let member = current.as(MemberAccessExprSyntax.self) {
            guard member.declName.baseName.hasText("baseAddress"), let base = member.base else {
                return false
            }
            current = base
        } else if expression.is(ForceUnwrapExprSyntax.self) { return false }
        return current.as(DeclReferenceExprSyntax.self)?.baseName.text == parameter
    }
}

fileprivate extension Finding.Message {
    static func escapedPointer(_ name: String) -> Finding.Message {
        "the pointer from '\(name)' is valid only inside the closure. Returning it is a lifetime bug. Do the work inside the closure, or use a 'Span'"
    }
}
