import SwiftSyntax

/// Remove `public` on members inside non-public types where it has no effect.
///
/// A `public` member inside an `internal`, `private`, or `fileprivate` type is effectively
/// limited to the enclosing type's access level. The `public` modifier is misleading.
///
/// This rule checks struct, class, enum, and actor declarations. It does NOT flag
/// members of `public` or `package` types (where `public` is meaningful).
///
/// Lint: If a `public` member is found inside a non-public type, a lint warning is raised.
@_spi(Rules)
public final class RedundantPublic: SyntaxLintRule {

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    checkMembers(of: node.modifiers, members: node.memberBlock.members)
    return .visitChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    checkMembers(of: node.modifiers, members: node.memberBlock.members)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    checkMembers(of: node.modifiers, members: node.memberBlock.members)
    return .visitChildren
  }

  public override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    checkMembers(of: node.modifiers, members: node.memberBlock.members)
    return .visitChildren
  }

  private func checkMembers(
    of typeModifiers: DeclModifierListSyntax,
    members: MemberBlockItemListSyntax
  ) {
    // Only check non-public types. If the type is public or package, `public` on members
    // is meaningful.
    if let accessModifier = typeModifiers.accessLevelModifier,
      case .keyword(let keyword) = accessModifier.name.tokenKind,
      keyword == .public || keyword == .package
    {
      return
    }

    // The type is internal/private/fileprivate (or has no explicit access level = internal).
    for member in members {
      guard let decl = member.decl.asProtocol(WithModifiersSyntax.self),
        let memberModifier = decl.modifiers.accessLevelModifier,
        memberModifier.detail == nil,
        case .keyword(.public) = memberModifier.name.tokenKind
      else {
        continue
      }

      diagnose(.removeRedundantPublic, on: memberModifier.name)
    }
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantPublic: Finding.Message =
    "remove redundant 'public'; the enclosing type is not public"
}
