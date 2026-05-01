import SwiftSyntax

/// `String.data(using: .utf8)` returns `Data?` , even though UTF-8 encoding can never fail. Prefer
/// the non-optional `Data(_:)` initializer that takes a `String.UTF8View` : `Data("foo".utf8)`
/// instead of `"foo".data(using: .utf8)` .
///
/// Lint: A warning is raised for any call of the form `<expr>.data(using: .utf8)` . Other encodings
/// ( `.ascii` , `.unicode` , etc.) are not flagged because they really can fail.
final class PreferNonOptionalDataInit: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "data",
              node.arguments.count == 1,
              let only = node.arguments.first,
              only.label?.text == "using",
              let encoding = only.expression.as(MemberAccessExprSyntax.self),
              encoding.declName.baseName.text == "utf8" else { return .visitChildren }
        diagnose(.preferNonOptionalDataInit, on: member.declName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let preferNonOptionalDataInit: Finding.Message =
        "prefer 'Data(<string>.utf8)' over '<string>.data(using: .utf8)' — UTF-8 encoding cannot fail"
}
