import SwiftSyntax

/// Prefer `AnyObject` over `class` for class-constrained protocols.
///
/// The `class` keyword in protocol inheritance clauses was replaced by `AnyObject` in Swift 4.1.
/// Using `AnyObject` is the modern, preferred spelling.
///
/// Lint: A protocol inheriting from `class` instead of `AnyObject` raises a warning.
///
/// Rewrite: `class` is replaced with `AnyObject` in the inheritance clause.
final class PreferAnyObject: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .types }

    /// Replace `class` with `AnyObject` in a protocol's inheritance clause. Called from
    /// `CompactStageOneRewriter.visit(_: ProtocolDeclSyntax)`.
    static func apply(_ node: ProtocolDeclSyntax, context: Context) -> ProtocolDeclSyntax {
        guard let inheritanceClause = node.inheritanceClause else { return node }

        var foundViolation = false
        let newInheritedTypes = inheritanceClause.inheritedTypes.map {
            inherited -> InheritedTypeSyntax in
            guard let classRestriction = inherited.type.as(ClassRestrictionTypeSyntax.self) else {
                return inherited
            }

            foundViolation = true
            Self.diagnose(
                .preferAnyObject,
                on: classRestriction.classKeyword,
                context: context
            )

            let anyObjectType = IdentifierTypeSyntax(
                name: .identifier(
                    "AnyObject",
                    leadingTrivia: classRestriction.classKeyword.leadingTrivia,
                    trailingTrivia: classRestriction.classKeyword.trailingTrivia
                )
            )
            return inherited.with(\.type, TypeSyntax(anyObjectType))
        }

        guard foundViolation else { return node }

        let newClause = inheritanceClause.with(
            \.inheritedTypes,
            InheritedTypeListSyntax(newInheritedTypes)
        )
        return node.with(\.inheritanceClause, newClause)
    }
}

extension Finding.Message {
    fileprivate static let preferAnyObject: Finding.Message =
        "use 'AnyObject' instead of 'class' for class-constrained protocols"
}
