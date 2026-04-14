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
///
/// Format: The redundant `public` modifier is removed.
@_spi(Rules)
public final class RedundantPublic: SyntaxFormatRule {

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)
    return DeclSyntax(removePublicFromMembers(of: visited))
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    return DeclSyntax(removePublicFromMembers(of: visited))
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(EnumDeclSyntax.self)
    return DeclSyntax(removePublicFromMembers(of: visited))
  }

  public override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ActorDeclSyntax.self)
    return DeclSyntax(removePublicFromMembers(of: visited))
  }

  private func removePublicFromMembers<
    Decl: DeclGroupSyntax & WithModifiersSyntax
  >(of decl: Decl) -> Decl {
    // Only check non-public types.
    if let accessModifier = decl.modifiers.accessLevelModifier,
      case .keyword(let keyword) = accessModifier.name.tokenKind,
      keyword == .public || keyword == .package
    {
      return decl
    }

    var modified = false
    let newMembers = decl.memberBlock.members.map { member -> MemberBlockItemSyntax in
      let rewritten = rewrittenDecl(member.decl)
      guard rewritten.id != member.decl.id else { return member }
      modified = true
      return member.with(\.decl, rewritten)
    }

    guard modified else { return decl }
    return decl.with(\.memberBlock, decl.memberBlock.with(\.members, MemberBlockItemListSyntax(newMembers)))
  }

  private func rewrittenDecl(_ decl: DeclSyntax) -> DeclSyntax {
    switch Syntax(decl).as(SyntaxEnum.self) {
    case .functionDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.funcKeyword))
    case .variableDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.bindingSpecifier))
    case .classDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.classKeyword))
    case .structDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.structKeyword))
    case .enumDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.enumKeyword))
    case .protocolDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.protocolKeyword))
    case .typeAliasDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.typealiasKeyword))
    case .initializerDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.initKeyword))
    case .subscriptDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.subscriptKeyword))
    case .actorDecl(let d): return DeclSyntax(removePublic(from: d, keywordKeyPath: \.actorKeyword))
    default: return decl
    }
  }

  private func removePublic<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard let memberModifier = decl.modifiers.accessLevelModifier,
      memberModifier.detail == nil,
      case .keyword(.public) = memberModifier.name.tokenKind
    else {
      return decl
    }

    diagnose(.removeRedundantPublic, on: memberModifier.name)

    var result = decl
    let savedTrivia = memberModifier.leadingTrivia
    result.modifiers.remove(anyOf: [.public])
    if result.modifiers.first != nil {
      result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
    } else {
      result[keyPath: keywordKeyPath].leadingTrivia = savedTrivia
    }
    return result
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantPublic: Finding.Message =
    "remove redundant 'public'; the enclosing type is not public"
}
