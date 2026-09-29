import SwiftSyntax

/// Flag the `NSAttributedString` attribute walk in favour of `AttributedString.runs` .
///
/// `enumerateAttributes(in:options:using:)` and `enumerateAttribute(_:in:options:using:)` walk the
/// reference type through an Objective-C block with an `NSRange` and an untyped attribute
/// dictionary. `AttributedString.runs` is a Swift collection. Each run carries typed attributes and
/// a `Range<AttributedString.Index>` , and a `for` loop iterates it.
///
/// TextKit code that must keep an `NSAttributedString` can ignore the finding with `// sm:ignore` .
///
/// Lint: A call to `enumerateAttributes` or `enumerateAttribute` with an `in:` argument raises a
/// warning.
final class UseRunsNotEnumerateAttributes: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName
            ?? node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName

        guard let name,
              node.arguments.contains(where: { $0.label?.text == "in" })
        else { return .visitChildren }

        if name.hasText("enumerateAttributes") {
            diagnose(.enumerateAttributes, on: name)
        } else if name.hasText("enumerateAttribute") { diagnose(.enumerateAttribute, on: name) }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let enumerateAttributes: Finding.Message =
        "'enumerateAttributes(in:)' walks an 'NSAttributedString'. Iterate 'AttributedString.runs' instead"
    static let enumerateAttribute: Finding.Message =
        "'enumerateAttribute(_:in:)' walks an 'NSAttributedString'. Iterate 'AttributedString.runs' instead"
}
