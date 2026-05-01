import SwiftSyntax

/// Replace `@UIApplicationMain` and `@NSApplicationMain` with `@main` .
///
/// These attributes were deprecated in favor of `@main` (SE-0383, Swift 5.3+).
///
/// Lint: Using `@UIApplicationMain` or `@NSApplicationMain` raises a warning.
///
/// Rewrite: The attribute is replaced with `@main` .
final class PreferMainAttribute: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    static func transform(
        _ node: AttributeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> AttributeSyntax {
        guard let identType = node.attributeName.as(IdentifierTypeSyntax.self) else { return node }

        let name = identType.name.text
        guard name == "UIApplicationMain" || name == "NSApplicationMain" else { return node }

        Self.diagnose(.useMainAttribute(replacing: name), on: node.atSign, context: context)

        let newIdent = identType.with(
            \.name,
            identType.name.with(\.tokenKind, .identifier("main"))
        )
        return node.with(\.attributeName, TypeSyntax(newIdent))
    }
}

fileprivate extension Finding.Message {
    static func useMainAttribute(replacing name: String) -> Finding.Message {
        "replace '@\(name)' with '@main'"
    }
}
