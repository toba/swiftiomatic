import SwiftSyntax

/// Replace `@UIApplicationMain` and `@NSApplicationMain` with `@main`.
///
/// These attributes were deprecated in favor of `@main` (SE-0383, Swift 5.3+).
///
/// Lint: Using `@UIApplicationMain` or `@NSApplicationMain` raises a warning.
///
/// Format: The attribute is replaced with `@main`.
@_spi(Rules)
public final class PreferMainAttribute: SyntaxFormatRule {

  public override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
    guard let identType = node.attributeName.as(IdentifierTypeSyntax.self) else {
      return node
    }

    let name = identType.name.text
    guard name == "UIApplicationMain" || name == "NSApplicationMain" else {
      return node
    }

    diagnose(.useMainAttribute(replacing: name), on: node.atSign)

    let newIdent = identType.with(
      \.name, identType.name.with(\.tokenKind, .identifier("main"))
    )
    return node.with(\.attributeName, TypeSyntax(newIdent))
  }
}

extension Finding.Message {
  fileprivate static func useMainAttribute(replacing name: String) -> Finding.Message {
    "replace '@\(name)' with '@main'"
  }
}
