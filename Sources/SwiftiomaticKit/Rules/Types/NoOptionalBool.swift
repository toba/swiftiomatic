import SwiftSyntax

/// Optional booleans are confusing — three states (`true`, `false`, `nil`) where two are usually
/// enough. Prefer a non-optional `Bool` with a sensible default, or model the third state with an
/// enum so the cases are named.
///
/// Lint: A warning is raised for any `Bool?` type annotation, `Bool?` written as an expression
/// type, or an `Optional<Bool>.some(...)` call wrapping a boolean literal.
final class NoOptionalBool: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

    override func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
        if node.wrappedType.as(IdentifierTypeSyntax.self)?.name.text == "Bool" {
            diagnose(.noOptionalBool, on: node)
        }
        return .visitChildren
    }

    override func visit(_ node: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind {
        if node.expression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Bool" {
            diagnose(.noOptionalBool, on: node)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "some",
            member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Optional",
            let only = node.arguments.first,
            node.arguments.count == 1,
            only.expression.is(BooleanLiteralExprSyntax.self)
        else {
            return .visitChildren
        }
        diagnose(.noOptionalBool, on: node)
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let noOptionalBool: Finding.Message =
        "prefer a non-optional 'Bool' (with a default) or an enum over 'Bool?'"
}
