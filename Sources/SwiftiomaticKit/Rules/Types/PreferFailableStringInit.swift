import SwiftSyntax

/// `String(decoding: data, as: UTF8.self)` silently substitutes `U+FFFD` for invalid bytes,
/// hiding decoding errors. Prefer the failable `String(bytes: data, encoding: .utf8)` initializer
/// so the caller can handle invalid input explicitly.
///
/// Lint: A warning is raised for any call of the form `String(decoding:as:)` or
/// `String.init(decoding:as:)` whose `as:` argument is `UTF8.self`. Other unicode codecs
/// (`UTF16.self`, etc.) are not flagged.
final class PreferFailableStringInit: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.arguments.map(\.label?.text) == ["decoding", "as"],
            let last = node.arguments.last?.expression.as(MemberAccessExprSyntax.self),
            last.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "UTF8",
            last.declName.baseName.text == "self"
        else {
            return .visitChildren
        }

        let called = node.calledExpression
        if let ref = called.as(DeclReferenceExprSyntax.self), ref.baseName.text == "String" {
            diagnose(.preferFailableStringInit, on: called)
            return .visitChildren
        }
        if let member = called.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "init",
            member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "String"
        {
            diagnose(.preferFailableStringInit, on: called)
        }
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let preferFailableStringInit: Finding.Message =
        "prefer failable 'String(bytes:encoding:)' over 'String(decoding:as: UTF8.self)' which silently substitutes invalid bytes"
}
