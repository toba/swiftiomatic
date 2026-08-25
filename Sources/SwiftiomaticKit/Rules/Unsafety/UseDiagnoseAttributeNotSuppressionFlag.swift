import SwiftSyntax

/// Flag a module-wide diagnostic flag in a package manifest in favour of the SE-0522 attribute.
///
/// `-suppress-warnings` , `-Wwarning` and `-Werror` apply to every file the target compiles, so one
/// declaration that needs the exemption buys silence for the whole module. `@diagnose` sits on that
/// declaration, and the next reader sees which code the exemption covers and which it does not.
///
/// ```swift
/// @diagnose(DeprecatedDeclaration, as: ignored)
/// func legacy() {}
/// ```
///
/// Lint: A string literal naming one of those flags inside an `unsafeFlags` argument raises a
/// warning.
final class UseDiagnoseAttributeNotSuppressionFlag: LintSyntaxRule<LintOnlyValue>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .unsafety }

    private static let supersededFlags: Set<String> = [
        "-Werror", "-Wwarning", "-suppress-warnings",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "unsafeFlags" else { return .visitChildren }

        // `unsafeFlags` takes one array, so the walk goes through it rather than over the argument
        // list
        let literals = node.arguments.lazy
            .compactMap { $0.expression.as(ArrayExprSyntax.self) }
            .flatMap(\.elements)
            .compactMap { $0.expression.as(StringLiteralExprSyntax.self) }

        for literal in literals {
            guard let text = literal.representedLiteralValue,
                  Self.supersededFlags.contains(text) else { continue }
            diagnose(.useDiagnoseAttribute(flag: text), on: literal)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func useDiagnoseAttribute(flag: String) -> Finding.Message {
        """
        '\(flag)' changes diagnostics for the whole module — scope it with \
        '@diagnose(GroupID, as: ignored)' (SE-0522) on the declaration that needs it
        """
    }
}
