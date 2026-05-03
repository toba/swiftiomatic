import SwiftSyntax

/// Avoid naming enum cases or static members `none` .
///
/// A `case none` or `static let none` (or `static var` / `class var` ) can be confused with
/// `Optional<T>.none` . Especially when the enclosing type itself becomes optional, the compiler
/// will silently prefer `Optional.none` , leading to subtle bugs.
///
/// Lint: A warning is raised for any `case none` (without associated values), or any `static` /
/// `class` property named `none` .
///
/// Rewrite: Not auto-fixed; renaming requires understanding the call sites.
final class NoCaseNamedNone: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    static func transform(
        _ node: EnumCaseElementSyntax,
        original _: EnumCaseElementSyntax,
        parent _: Syntax?,
        context: Context
    ) -> EnumCaseElementSyntax {
        let hasParameters = !(node.parameterClause?.parameters.isEmpty ?? true)

        if !hasParameters, isNoneIdentifier(node.name) {
            Self.diagnose(.avoidNoneEnumCase, on: node.name, context: context)
        }
        return node
    }

    static func transform(
        _ node: VariableDeclSyntax,
        original _: VariableDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let kind: String? =
            if node.modifiers.contains(.class) { "class" }
            else if node.modifiers.contains(.static) { "static" }
            else { nil }

        if let kind {
            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      isNoneIdentifier(pattern.identifier) else { continue }
                Self.diagnose(
                    .avoidNoneStaticMember(kind: kind),
                    on: pattern.identifier,
                    context: context
                )
            }
        }

        return DeclSyntax(node)
    }

    private static func isNoneIdentifier(_ token: TokenSyntax) -> Bool {
        token.tokenKind == .identifier("none") || token.tokenKind == .identifier("`none`")
    }
}

fileprivate extension Finding.Message {
    static let avoidNoneEnumCase: Finding.Message =
        "avoid naming an enum case 'none' as it can conflict with 'Optional<T>.none'"

    static func avoidNoneStaticMember(kind: String) -> Finding.Message {
        "avoid naming a '\(kind)' member 'none' as it can conflict with 'Optional<T>.none'"
    }
}
