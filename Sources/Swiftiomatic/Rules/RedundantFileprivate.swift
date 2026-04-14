import SwiftSyntax

/// Prefer `private` over `fileprivate` where they are equivalent.
///
/// In Swift 4+, `private` members are accessible from extensions of the same type in
/// the same file. When a file contains only one logical type (a single type declaration
/// plus extensions of that same type), `fileprivate` on members is equivalent to `private`.
///
/// This rule only applies when the file contains a single logical type with no nested
/// type declarations (nested types can access `fileprivate` but not `private` members
/// of their parent).
///
/// Lint: A lint warning is raised for `fileprivate` members that could be `private`.
///
/// Format: `fileprivate` is replaced with `private`.
@_spi(Rules)
public final class RedundantFileprivate: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  /// The name of the single logical type in the file, if any.
  private var singleTypeName: String?

  /// Whether the single logical type (or its extensions) contains nested type declarations.
  private var hasNestedTypes = false

  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    // Phase 1: Analyze the file structure to determine if it's a single-type file.
    analyzeFileStructure(node.statements)

    guard singleTypeName != nil, !hasNestedTypes else {
      return node
    }

    // Phase 2: Rewrite fileprivate → private on members inside the type and its extensions.
    var result = node
    result.statements = rewriteStatements(node.statements)
    return result
  }

  // MARK: - Phase 1: File Structure Analysis

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

  // MARK: - Phase 2: Rewriting

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

extension Finding.Message {
  fileprivate static let replaceFileprivateWithPrivate: Finding.Message =
    "replace 'fileprivate' with 'private'; no other type in this file needs broader access"
}
