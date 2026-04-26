import SwiftSyntax

/// Avoid naming enum cases or static members `none`.
///
/// A `case none` or `static let none` (or `static var`/`class var`) can be confused with
/// `Optional<T>.none`. Especially when the enclosing type itself becomes optional, the compiler
/// will silently prefer `Optional.none`, leading to subtle bugs.
///
/// Lint: A warning is raised for any `case none` (without associated values), or any `static`/
/// `class` property named `none`.
///
/// Rewrite: Not auto-fixed; renaming requires understanding the call sites.
final class AvoidNoneName: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    override func visit(_ node: EnumCaseElementSyntax) -> EnumCaseElementSyntax {
        let hasParameters = !(node.parameterClause?.parameters.isEmpty ?? true)
        if !hasParameters, isNoneIdentifier(node.name) {
            diagnose(.avoidNoneEnumCase, on: node.name)
        }
        return super.visit(node)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let kind: String? = {
            if node.modifiers.contains(.class) {
                return "class"
            }
            if node.modifiers.contains(.static) {
                return "static"
            }
            return nil
        }()

        if let kind {
            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                    isNoneIdentifier(pattern.identifier)
                else { continue }
                diagnose(.avoidNoneStaticMember(kind: kind), on: pattern.identifier)
            }
        }

        return super.visit(node)
    }

    private func isNoneIdentifier(_ token: TokenSyntax) -> Bool {
        token.tokenKind == .identifier("none") || token.tokenKind == .identifier("`none`")
    }
}

extension Finding.Message {
    fileprivate static let avoidNoneEnumCase: Finding.Message =
        "avoid naming an enum case 'none' as it can conflict with 'Optional<T>.none'"

    fileprivate static func avoidNoneStaticMember(kind: String) -> Finding.Message {
        "avoid naming a '\(kind)' member 'none' as it can conflict with 'Optional<T>.none'"
    }
}
