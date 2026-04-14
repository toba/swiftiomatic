import SwiftSyntax

/// Remove access control on extension members that match the extension's own access level.
///
/// When an extension declares an access level (e.g. `public extension Foo`), members that
/// repeat that same access level are redundant.
///
/// For example: `public extension Foo { public func bar() {} }` — the `public` on `bar`
/// is redundant because it matches the extension's access level.
///
/// Lint: If a member has the same access level as its containing extension, a lint warning is raised.
@_spi(Rules)
public final class RedundantExtensionACL: SyntaxLintRule {

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    // Only check extensions that have an explicit access level.
    guard let extensionModifier = node.modifiers.accessLevelModifier,
      case .keyword(let extensionKeyword) = extensionModifier.name.tokenKind
    else {
      return .visitChildren
    }

    // Check each member for a matching access level.
    for member in node.memberBlock.members {
      guard let decl = member.decl.asProtocol(WithModifiersSyntax.self),
        let memberModifier = decl.modifiers.accessLevelModifier,
        memberModifier.detail == nil,  // skip `public(set)` etc.
        case .keyword(let memberKeyword) = memberModifier.name.tokenKind,
        memberKeyword == extensionKeyword
      else {
        continue
      }

      diagnose(
        .removeRedundantExtensionACL(keyword: memberModifier.name.text),
        on: memberModifier.name
      )
    }

    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantExtensionACL(keyword: String) -> Finding.Message {
    "remove redundant '\(keyword)'; it matches the extension's access level"
  }
}
