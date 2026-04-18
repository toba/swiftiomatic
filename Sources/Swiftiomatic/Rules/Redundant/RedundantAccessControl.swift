//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Unified rule that removes or replaces redundant access control modifiers.
///
/// Combines four checks:
///
/// 1. **Redundant `internal`** — removes explicit `internal` since it is the default.
///    Does NOT remove `internal(set)`, which is meaningful on properties with a higher
///    getter access level (e.g. `public internal(set) var`).
///
/// 2. **Redundant `public`** — removes `public` on members inside non-public types
///    where it has no effect. Does NOT flag members of `public` or `package` types.
///
/// 3. **Redundant extension ACL** — removes access control on extension members that
///    match the extension's own access level.
///
/// 4. **Redundant `fileprivate`** — converts `fileprivate` to `private` where equivalent.
///    Only applies when the file contains a single logical type with no nested type
///    declarations.
///
/// Lint: Raises warnings for any of the above redundancies.
///
/// Format: Removes or replaces the redundant modifier.
@_spi(Rules)
public final class RedundantAccessControl: SyntaxFormatRule {
  public override class var group: ConfigGroup? { .removeRedundant }

  public override class var isOptIn: Bool { true }

  // MARK: - RedundantFileprivate State

  /// The name of the single logical type in the file, if any.
  private var singleTypeName: String?

  /// Whether the single logical type (or its extensions) contains nested type declarations.
  private var hasNestedTypes = false

  // MARK: - RedundantFileprivate: SourceFileSyntax Visitor

  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    // Phase 1: Analyze the file structure to determine if it's a single-type file.
    analyzeFileStructure(node.statements)

    // Always visit children so the other checks (internal, public, extension ACL) run.
    let visited = super.visit(node)
    var result = visited.cast(SourceFileSyntax.self)

    guard singleTypeName != nil, !hasNestedTypes else {
      return result
    }

    // Phase 2: Rewrite fileprivate → private on members inside the type and its extensions.
    result.statements = rewriteStatements(result.statements)
    return result
  }

  // MARK: - RedundantInternal: Per-Decl Visitors

  public override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ActorDeclSyntax.self)
    let afterInternal = removeRedundantInternal(from: visited, keywordKeyPath: \.actorKeyword)
    return DeclSyntax(removePublicFromMembers(of: afterInternal))
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)
    let afterInternal = removeRedundantInternal(from: visited, keywordKeyPath: \.classKeyword)
    return DeclSyntax(removePublicFromMembers(of: afterInternal))
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(EnumDeclSyntax.self)
    let afterInternal = removeRedundantInternal(from: visited, keywordKeyPath: \.enumKeyword)
    return DeclSyntax(removePublicFromMembers(of: afterInternal))
  }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.funcKeyword))
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.initKeyword))
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ProtocolDeclSyntax.self)
    return DeclSyntax(removeRedundantInternal(from: visited, keywordKeyPath: \.protocolKeyword))
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    let afterInternal = removeRedundantInternal(from: visited, keywordKeyPath: \.structKeyword)
    return DeclSyntax(removePublicFromMembers(of: afterInternal))
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.subscriptKeyword))
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.typealiasKeyword))
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.bindingSpecifier))
  }

  // MARK: - RedundantExtensionACL: ExtensionDeclSyntax Visitor

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
      let rewritten = rewrittenDeclForExtensionACL(member.decl, extensionKeyword: extensionKeyword)
      guard rewritten.id != member.decl.id else { return member }
      modified = true
      return member.with(\.decl, rewritten)
    }

    guard modified else { return DeclSyntax(visited) }
    let newMemberBlock = visited.memberBlock.with(
      \.members, MemberBlockItemListSyntax(newMembers))
    return DeclSyntax(visited.with(\.memberBlock, newMemberBlock))
  }

  // MARK: - RedundantInternal: Helpers

  /// Removes a redundant `internal` modifier from the given declaration, if present.
  ///
  /// `internal(set)` is preserved because it is meaningful as a setter access restriction.
  private func removeRedundantInternal<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard let internalModifier = decl.modifiers.accessLevelModifier,
      internalModifier.name.tokenKind == .keyword(.internal),
      internalModifier.detail == nil  // skip `internal(set)`
    else {
      return decl
    }

    diagnose(.removeRedundantInternal, on: internalModifier.name)

    var result = decl
    result.modifiers.remove(anyOf: [.internal])

    // Transfer the leading trivia from the removed modifier to the next token
    // (either the next modifier or the declaration keyword).
    if result.modifiers.first != nil {
      result.modifiers[result.modifiers.startIndex].leadingTrivia =
        internalModifier.leadingTrivia
    } else {
      result[keyPath: keywordKeyPath].leadingTrivia = internalModifier.leadingTrivia
    }

    return result
  }

  // MARK: - RedundantPublic: Helpers

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
      let rewritten = rewrittenDeclForPublic(member.decl)
      guard rewritten.id != member.decl.id else { return member }
      modified = true
      return member.with(\.decl, rewritten)
    }

    guard modified else { return decl }
    return decl.with(\.memberBlock, decl.memberBlock.with(\.members, MemberBlockItemListSyntax(newMembers)))
  }

  private func rewrittenDeclForPublic(_ decl: DeclSyntax) -> DeclSyntax {
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

  // MARK: - RedundantExtensionACL: Helpers

  private func rewrittenDeclForExtensionACL(_ decl: DeclSyntax, extensionKeyword: Keyword) -> DeclSyntax {
    switch Syntax(decl).as(SyntaxEnum.self) {
    case .functionDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.funcKeyword))
    case .variableDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.bindingSpecifier))
    case .classDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.classKeyword))
    case .structDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.structKeyword))
    case .enumDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.enumKeyword))
    case .protocolDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.protocolKeyword))
    case .typeAliasDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.typealiasKeyword))
    case .initializerDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.initKeyword))
    case .subscriptDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.subscriptKeyword))
    case .actorDecl(let d): return DeclSyntax(removeExtensionACLModifier(from: d, keyword: extensionKeyword, keywordKeyPath: \.actorKeyword))
    default: return decl
    }
  }

  private func removeExtensionACLModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
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

  // MARK: - RedundantFileprivate: Phase 1 — File Structure Analysis

  /// Determines whether the file contains only one logical type (primary type + extensions).
  private func analyzeFileStructure(_ statements: CodeBlockItemListSyntax) {
    var primaryTypeName: String?

    for item in statements {
      switch item.item {
      case .decl(let decl):
        if let name = topLevelTypeName(decl) {
          if primaryTypeName == nil {
            primaryTypeName = name
          } else if primaryTypeName != name {
            // Multiple different type names — not a single-type file.
            singleTypeName = nil
            return
          }
        } else if decl.is(ImportDeclSyntax.self) {
          continue
        } else if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
          analyzeIfConfig(ifConfig, primaryTypeName: &primaryTypeName)
          if singleTypeName == nil && primaryTypeName == nil {
            return
          }
        } else {
          // Top-level code (functions, variables, etc.) — not a single-type file.
          singleTypeName = nil
          return
        }
      default:
        // Expressions, statements at file scope — not a single-type file.
        singleTypeName = nil
        return
      }
    }

    singleTypeName = primaryTypeName

    guard primaryTypeName != nil else { return }

    // Check for nested types in the primary type and its extensions.
    for item in statements {
      guard case .decl(let decl) = item.item else { continue }
      if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
        if ifConfigHasNestedTypes(ifConfig) {
          hasNestedTypes = true
          return
        }
      } else if declHasNestedTypes(decl) {
        hasNestedTypes = true
        return
      }
    }
  }

  /// Analyzes `#if` blocks for top-level type declarations.
  private func analyzeIfConfig(
    _ ifConfig: IfConfigDeclSyntax,
    primaryTypeName: inout String?
  ) {
    for clause in ifConfig.clauses {
      guard case .statements(let stmts)? = clause.elements else { continue }
      for item in stmts {
        guard case .decl(let decl) = item.item else {
          singleTypeName = nil
          return
        }
        if let name = topLevelTypeName(decl) {
          if primaryTypeName == nil {
            primaryTypeName = name
          } else if primaryTypeName != name {
            singleTypeName = nil
            return
          }
        } else if decl.is(ImportDeclSyntax.self) {
          continue
        } else if let nested = decl.as(IfConfigDeclSyntax.self) {
          analyzeIfConfig(nested, primaryTypeName: &primaryTypeName)
          if singleTypeName == nil && primaryTypeName == nil {
            return
          }
        } else {
          singleTypeName = nil
          return
        }
      }
    }
  }

  /// Returns the type name for a top-level type or extension declaration.
  private func topLevelTypeName(_ decl: DeclSyntax) -> String? {
    if let structDecl = decl.as(StructDeclSyntax.self) {
      return structDecl.name.text
    } else if let classDecl = decl.as(ClassDeclSyntax.self) {
      return classDecl.name.text
    } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
      return enumDecl.name.text
    } else if let actorDecl = decl.as(ActorDeclSyntax.self) {
      return actorDecl.name.text
    } else if let extDecl = decl.as(ExtensionDeclSyntax.self) {
      // Only simple names, not `Foo.Bar` nested type extensions.
      guard extDecl.extendedType.as(IdentifierTypeSyntax.self) != nil else { return nil }
      return extDecl.extendedType.trimmedDescription
    }
    return nil
  }

  /// Returns true if the declaration body contains nested type declarations.
  private func declHasNestedTypes(_ decl: DeclSyntax) -> Bool {
    let members: MemberBlockItemListSyntax?
    if let s = decl.as(StructDeclSyntax.self) { members = s.memberBlock.members }
    else if let c = decl.as(ClassDeclSyntax.self) { members = c.memberBlock.members }
    else if let e = decl.as(EnumDeclSyntax.self) { members = e.memberBlock.members }
    else if let a = decl.as(ActorDeclSyntax.self) { members = a.memberBlock.members }
    else if let x = decl.as(ExtensionDeclSyntax.self) { members = x.memberBlock.members }
    else { return false }

    guard let members else { return false }
    return members.contains { isTypeDeclaration($0.decl) }
  }

  /// Returns true if any clause's body contains nested type declarations.
  private func ifConfigHasNestedTypes(_ ifConfig: IfConfigDeclSyntax) -> Bool {
    for clause in ifConfig.clauses {
      guard case .statements(let stmts)? = clause.elements else { continue }
      for item in stmts {
        guard case .decl(let decl) = item.item else { continue }
        if let nested = decl.as(IfConfigDeclSyntax.self) {
          if ifConfigHasNestedTypes(nested) { return true }
        } else if declHasNestedTypes(decl) {
          return true
        }
      }
    }
    return false
  }

  /// Returns true if the declaration is a type (struct, class, enum, actor, protocol).
  private func isTypeDeclaration(_ decl: DeclSyntax) -> Bool {
    decl.is(StructDeclSyntax.self)
      || decl.is(ClassDeclSyntax.self)
      || decl.is(EnumDeclSyntax.self)
      || decl.is(ActorDeclSyntax.self)
      || decl.is(ProtocolDeclSyntax.self)
  }

  // MARK: - RedundantFileprivate: Phase 2 — Rewriting

  /// Rewrites `fileprivate` to `private` on member declarations.
  private func rewriteStatements(
    _ statements: CodeBlockItemListSyntax
  ) -> CodeBlockItemListSyntax {
    let newItems = statements.map { item -> CodeBlockItemSyntax in
      guard case .decl(let decl) = item.item else { return item }

      if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
        var result = item
        result.item = .decl(DeclSyntax(rewriteIfConfig(ifConfig)))
        return result
      }

      guard let rewritten = rewriteMembersInDecl(decl) else { return item }
      var result = item
      result.item = .decl(rewritten)
      return result
    }
    return CodeBlockItemListSyntax(newItems)
  }

  /// Rewrites `fileprivate` members inside `#if` blocks.
  private func rewriteIfConfig(_ ifConfig: IfConfigDeclSyntax) -> IfConfigDeclSyntax {
    let newClauses = ifConfig.clauses.map { clause -> IfConfigClauseSyntax in
      guard case .statements(let stmts)? = clause.elements else { return clause }
      var result = clause
      result.elements = .statements(rewriteStatements(stmts))
      return result
    }
    var result = ifConfig
    result.clauses = IfConfigClauseListSyntax(newClauses)
    return result
  }

  /// Rewrites `fileprivate` on members of the given type or extension declaration.
  private func rewriteMembersInDecl(_ decl: DeclSyntax) -> DeclSyntax? {
    if var structDecl = decl.as(StructDeclSyntax.self) {
      structDecl.memberBlock.members = rewriteMembers(structDecl.memberBlock.members)
      return DeclSyntax(structDecl)
    } else if var classDecl = decl.as(ClassDeclSyntax.self) {
      classDecl.memberBlock.members = rewriteMembers(classDecl.memberBlock.members)
      return DeclSyntax(classDecl)
    } else if var enumDecl = decl.as(EnumDeclSyntax.self) {
      enumDecl.memberBlock.members = rewriteMembers(enumDecl.memberBlock.members)
      return DeclSyntax(enumDecl)
    } else if var actorDecl = decl.as(ActorDeclSyntax.self) {
      actorDecl.memberBlock.members = rewriteMembers(actorDecl.memberBlock.members)
      return DeclSyntax(actorDecl)
    } else if var extDecl = decl.as(ExtensionDeclSyntax.self) {
      extDecl.memberBlock.members = rewriteMembers(extDecl.memberBlock.members)
      return DeclSyntax(extDecl)
    }
    return nil
  }

  /// Rewrites `fileprivate` to `private` on member declarations.
  private func rewriteMembers(
    _ members: MemberBlockItemListSyntax
  ) -> MemberBlockItemListSyntax {
    let newMembers = members.map { member -> MemberBlockItemSyntax in
      let decl = member.decl
      guard let rewritten = rewriteFileprivate(on: decl) else { return member }
      var result = member
      result.decl = rewritten
      return result
    }
    return MemberBlockItemListSyntax(newMembers)
  }

  /// Replaces `fileprivate` with `private` on a single member declaration, if applicable.
  private func rewriteFileprivate(on decl: DeclSyntax) -> DeclSyntax? {
    if let funcDecl = decl.as(FunctionDeclSyntax.self) {
      return DeclSyntax(replaceFileprivate(on: funcDecl))
    } else if let varDecl = decl.as(VariableDeclSyntax.self) {
      return DeclSyntax(replaceFileprivate(on: varDecl))
    } else if let initDecl = decl.as(InitializerDeclSyntax.self) {
      return DeclSyntax(replaceFileprivate(on: initDecl))
    } else if let subscriptDecl = decl.as(SubscriptDeclSyntax.self) {
      return DeclSyntax(replaceFileprivate(on: subscriptDecl))
    } else if let typealiasDecl = decl.as(TypeAliasDeclSyntax.self) {
      return DeclSyntax(replaceFileprivate(on: typealiasDecl))
    }
    // Don't touch nested types, enum cases, associated types, etc.
    return nil
  }

  /// Generic implementation: replaces `fileprivate` with `private` if present.
  private func replaceFileprivate<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    on decl: Decl
  ) -> Decl {
    guard decl.modifiers.contains(anyOf: [.fileprivate]) else {
      return decl
    }

    let newModifiers = decl.modifiers.map { modifier -> DeclModifierSyntax in
      var modifier = modifier
      if case .keyword(.fileprivate) = modifier.name.tokenKind {
        diagnose(.replaceFileprivateWithPrivate, on: modifier.name)
        modifier.name.tokenKind = .keyword(.private)
      }
      return modifier
    }

    var result = decl
    result.modifiers = DeclModifierListSyntax(newModifiers)
    return result
  }
}

// MARK: - Finding Messages

extension Finding.Message {
  fileprivate static let removeRedundantInternal: Finding.Message =
    "remove redundant 'internal' access modifier"

  fileprivate static let removeRedundantPublic: Finding.Message =
    "remove redundant 'public'; the enclosing type is not public"

  fileprivate static func removeRedundantExtensionACL(keyword: String) -> Finding.Message {
    "remove redundant '\(keyword)'; it matches the extension's access level"
  }

  fileprivate static let replaceFileprivateWithPrivate: Finding.Message =
    "replace 'fileprivate' with 'private'; no other type in this file needs broader access"
}
