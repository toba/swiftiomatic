import SwiftSyntax

/// Prefer `.scaledToFit()` / `.scaledToFill()` over `.aspectRatio(contentMode:)` with a constant
/// content mode.
///
/// SwiftUI's `scaledToFit()` and `scaledToFill()` are exact equivalents of
/// `aspectRatio(contentMode: .fit)` and `aspectRatio(contentMode: .fill)` respectively, and read
/// more clearly. The rewrite only fires when the call has a single `contentMode:` argument whose
/// value is a constant `.fit` / `.fill` (optionally spelled `ContentMode.fit` / `ContentMode.fill`).
/// A leading ratio argument, a non-constant content mode, or a differently-typed enum base leaves
/// the call untouched.
///
/// Lint: Using `aspectRatio(contentMode:)` with a constant content mode raises a warning.
///
/// Rewrite: `.aspectRatio(contentMode: .fit)` becomes `.scaledToFit()` and
/// `.aspectRatio(contentMode: .fill)` becomes `.scaledToFill()`.
final class UseScaledToFit: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .swiftui }

    static func transform(
        _ node: FunctionCallExprSyntax,
        original _: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // The called expression must be `<base>.aspectRatio` or a bare `aspectRatio`.
        let base: ExprSyntax?
        let calledToken: TokenSyntax
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self) {
            guard member.declName.baseName.text == "aspectRatio" else { return ExprSyntax(node) }
            base = member.base
            calledToken = member.declName.baseName
        } else if let declRef = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            guard declRef.baseName.text == "aspectRatio" else { return ExprSyntax(node) }
            base = nil
            calledToken = declRef.baseName
        } else {
            return ExprSyntax(node)
        }

        // Exactly one `contentMode:` argument whose value is a constant `.fit` / `.fill`.
        guard node.arguments.count == 1,
              let argument = node.arguments.first,
              argument.label?.text == "contentMode",
              let mode = argument.expression.as(MemberAccessExprSyntax.self),
              mode.isContentModeConstant,
              node.trailingClosure == nil,
              node.additionalTrailingClosures.isEmpty else { return ExprSyntax(node) }

        let modeName = mode.declName.baseName.text
        guard modeName == "fit" || modeName == "fill" else { return ExprSyntax(node) }

        let replacement = modeName == "fit" ? "scaledToFit" : "scaledToFill"
        Self.diagnose(.useScaledTo(replacement, insteadOf: modeName), on: calledToken, context: context)

        // Build `<base>.scaledToFit` (or a bare `scaledToFit`) and drop the arguments.
        let replacementName = DeclReferenceExprSyntax(baseName: .identifier(replacement))
        let newCalled: ExprSyntax =
            if let base {
                ExprSyntax(MemberAccessExprSyntax(base: base.trimmed, declName: replacementName))
            } else {
                ExprSyntax(replacementName)
            }

        let newNode = node
            .with(\.calledExpression, newCalled)
            .with(\.leftParen, node.leftParen?.with(\.trailingTrivia, []))
            .with(\.arguments, [])
            .with(\.rightParen, node.rightParen?.with(\.leadingTrivia, []))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)

        return ExprSyntax(newNode)
    }
}

private extension MemberAccessExprSyntax {
    /// A SwiftUI `ContentMode` constant: either implicit (`.fit`) or spelled `ContentMode.fit`.
    /// A differently-typed base (e.g. `CustomMode.fit`) is not a match.
    var isContentModeConstant: Bool {
        base == nil || base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "ContentMode"
    }
}

fileprivate extension Finding.Message {
    static func useScaledTo(_ replacement: String, insteadOf mode: String) -> Finding.Message {
        "use '.\(replacement)()' instead of '.aspectRatio(contentMode: .\(mode))'"
    }
}
