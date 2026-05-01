import SwiftSyntax

/// Replace `@_specialize` with `@specialize` .
///
/// `@_specialize` was the experimental, underscore-prefixed spelling. The official `@specialize`
/// attribute is available in Swift 6.3.
///
/// Lint: Using `@_specialize` raises a warning.
///
/// Rewrite: The attribute is replaced with `@specialize` , preserving its argument list (e.g.
/// `where` , `exported:` , `kind:` ).
final class PreferOfficialSpecialize: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    static func transform(
        _ node: AttributeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> AttributeSyntax {
        guard let identType = node.attributeName.as(IdentifierTypeSyntax.self) else { return node }

        guard identType.name.text == "_specialize" else { return node }

        Self.diagnose(.useSpecializeAttribute, on: node.atSign, context: context)

        let newIdent = identType.with(
            \.name,
            identType.name.with(\.tokenKind, .identifier("specialize"))
        )
        return node.with(\.attributeName, TypeSyntax(newIdent))
    }
}

fileprivate extension Finding.Message {
    static var useSpecializeAttribute: Finding.Message {
        "replace '@_specialize' with '@specialize'"
    }
}
