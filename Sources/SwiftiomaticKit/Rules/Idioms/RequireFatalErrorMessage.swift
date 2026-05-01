import SwiftSyntax

/// `fatalError` calls should include a descriptive message.
///
/// A bare `fatalError()` (or `fatalError("")` ) gives no context when the program crashes.
/// Including a message makes it far easier to diagnose the problem from the stack trace alone.
///
/// Lint: A warning is raised for `fatalError()` and `fatalError("")` .
///
/// Rewrite: Not auto-fixed; the message must be supplied by the author.
final class RequireFatalErrorMessage: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    static func transform(
        _ node: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        if isUnnamedFatalError(node) {
            Self.diagnose(.fatalErrorNeedsMessage, on: node, context: context)
        }
        return ExprSyntax(node)
    }

    private static func isUnnamedFatalError(_ node: FunctionCallExprSyntax) -> Bool {
        guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
              callee.baseName.text == "fatalError" else { return false }

        if node.arguments.isEmpty { return true }
        if node.arguments.count == 1,
           let only = node.arguments.first,
           only.label == nil,
           let stringLiteral = only.expression.as(StringLiteralExprSyntax.self),
           isEmptyStringLiteral(stringLiteral)
        {
            return true
        }
        return false
    }

    private static func isEmptyStringLiteral(_ node: StringLiteralExprSyntax) -> Bool {
        // No segments at all, or a single empty string segment.
        if node.segments.isEmpty { return true }

        for segment in node.segments {
            guard let stringSegment = segment.as(StringSegmentSyntax.self) else { return false }
            if !stringSegment.content.text.isEmpty { return false }
        }
        return true
    }
}

fileprivate extension Finding.Message {
    static let fatalErrorNeedsMessage: Finding.Message =
        "'fatalError' should include a descriptive message"
}
