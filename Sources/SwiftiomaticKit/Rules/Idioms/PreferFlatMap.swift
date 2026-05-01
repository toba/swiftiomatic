import SwiftSyntax

/// Prefer `flatMap` over `map { ... }.reduce([], +)` .
///
/// `flatMap` performs the concatenation in a single pass; `map` followed by `reduce([], +)`
/// allocates an intermediate array per element.
///
/// Lint: warns on `xs.map { ... }.reduce([], +)` .
final class PreferFlatMap: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "reduce",
              node.arguments.count == 2,
              let firstArray = node.arguments.first?.expression.as(ArrayExprSyntax.self),
              firstArray.elements.isEmpty,
              let secondRef = node.arguments.last?.expression.as(DeclReferenceExprSyntax.self),
              secondRef.baseName.text == "+" else { return .visitChildren }
        diagnose(.preferFlatMap, on: member.declName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let preferFlatMap: Finding.Message = "prefer 'flatMap' over 'map { ... }.reduce([], +)'"
}
