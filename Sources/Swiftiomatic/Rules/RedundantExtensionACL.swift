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
///
/// Format: The redundant access modifier is removed from the member.
@_spi(Rules)
public final class RedundantExtensionACL: SyntaxFormatRule {

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ExtensionDeclSyntax.self)

    // Only check extensions that have an explicit access level.
    guard let extensionModifier = visited.modifiers.accessLevelModifier,
      case .keyword(let extensionKeyword) = extensionModifier.name.tokenKind
    else {
      return DeclSyntax(visited)
    }

    var modified = false
    let newMembers = visited.memberBlock.members.map { member -> MemberBlockItemSyntax in
      let rewritten = rewrittenDecl(member.decl, extensionKeyword: extensionKeyword)
      guard rewritten.id != member.decl.id else { return member }
      modified = true
      return member.with(\.decl, rewritten)
    }

    guard modified else { return DeclSyntax(visited) }
    let newMemberBlock = visited.memberBlock.with(
      \.members, MemberBlockItemListSyntax(newMembers))
    return DeclSyntax(visited.with(\.memberBlock, newMemberBlock))
  }

  private func rewrittenDecl(_ decl: DeclSyntax, extensionKeyword: Keyword) -> DeclSyntax {
    switch Syntax(decl).as(SyntaxEnum.self) {
    case .functionDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.funcKeyword))
    case .variableDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.bindingSpecifier))
    case .classDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.classKeyword))
    case .structDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.structKeyword))
    case .enumDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.enumKeyword))
    case .protocolDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.protocolKeyword))
    case .typeAliasDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.typealiasKeyword))
    case .initializerDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.initKeyword))
    case .subscriptDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.subscriptKeyword))
    case .actorDecl(let d): return DeclSyntax(removeModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.actorKeyword))
    default: return decl
    }
  }

  private func removeModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keyword extensionKeyword: Keyword,
    keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard let memberModifier = decl.modifiers.accessLevelModifier,
      memberModifier.detail == nil,  // skip `public(set)` etc.
      case .keyword(let memberKeyword) = memberModifier.name.tokenKind,
      memberKeyword == extensionKeyword
    else {
      return decl
    }

    diagnose(
      .removeRedundantExtensionACL(keyword: memberModifier.name.text),
      on: memberModifier.name
    )

    var result = decl
    let savedTrivia = memberModifier.leadingTrivia
    result.modifiers.remove(anyOf: [extensionKeyword])
    if result.modifiers.first != nil {
      result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
    } else {
      result[keyPath: keywordKeyPath].leadingTrivia = savedTrivia
    }
    return result
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantExtensionACL(keyword: String) -> Finding.Message {
    "remove redundant '\(keyword)'; it matches the extension's access level"
  }
}
