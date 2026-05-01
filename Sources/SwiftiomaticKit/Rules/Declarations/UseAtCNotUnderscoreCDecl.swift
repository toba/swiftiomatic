import SwiftSyntax

/// Replace `@_cdecl` with `@c` .
///
/// `@_cdecl` was the experimental, underscore-prefixed spelling. SE-0407 promoted it to the
/// official `@c` attribute in Swift 6.3.
///
/// Lint: Using `@_cdecl` raises a warning.
///
/// Rewrite: The attribute is replaced with `@c` , preserving any argument list.
final class UseAtCNotUnderscoreCDecl: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    static func transform(
        _ node: AttributeSyntax,
        original _: AttributeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> AttributeSyntax {
        guard let identType = node.attributeName.as(IdentifierTypeSyntax.self) else { return node }

        guard identType.name.text == "_cdecl" else { return node }

        Self.diagnose(.useCAttribute, on: node.atSign, context: context)

        let newIdent = identType.with(
            \.name,
            identType.name.with(\.tokenKind, .identifier("c"))
        )
        return node.with(\.attributeName, TypeSyntax(newIdent))
    }
}

fileprivate extension Finding.Message {
    static var useCAttribute: Finding.Message { "replace '@_cdecl' with '@c'" }
}
