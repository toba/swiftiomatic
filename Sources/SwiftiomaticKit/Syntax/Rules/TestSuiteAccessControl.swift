import SwiftSyntax

/// Test methods should be `internal`; helper properties and functions should be `private`.
///
/// In test suites, test methods don't need explicit access control (internal is the default and
/// correct level). Non-test helpers should be `private` since they're only used within the suite.
///
/// Lint: A warning is raised for incorrect access control on test suite members.
///
/// Format: Access control is corrected.
final class TestSuiteAccessControl: RewriteSyntaxRule {

  override class var defaultHandling: RuleHandling { .off }

  private var framework: TestFramework?

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    setImportsXCTest(context: context, sourceFile: node)
    framework = detectTestFramework(in: node)
    return super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard let framework else { return DeclSyntax(node) }
    guard SwiftiomaticKit.isTestSuite(name: node.name.text, inheritanceClause: node.inheritanceClause,
      modifiers: node.modifiers, leadingTrivia: node.leadingTrivia, framework: framework)
    else { return DeclSyntax(node) }
    guard !hasParameterizedInit(node.memberBlock) else { return DeclSyntax(node) }

    var result = node
    result = removePublicModifier(from: result, keyword: \.classKeyword)
    result = result.with(\.memberBlock, rewriteMembers(result.memberBlock, framework: framework))
    return DeclSyntax(result)
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard let framework else { return DeclSyntax(node) }
    guard SwiftiomaticKit.isTestSuite(name: node.name.text, inheritanceClause: node.inheritanceClause,
      modifiers: node.modifiers, leadingTrivia: node.leadingTrivia, framework: framework)
    else { return DeclSyntax(node) }
    guard !hasParameterizedInit(node.memberBlock) else { return DeclSyntax(node) }

    var result = node
    result = removePublicModifier(from: result, keyword: \.structKeyword)
    result = result.with(\.memberBlock, rewriteMembers(result.memberBlock, framework: framework))
    return DeclSyntax(result)
  }

  // MARK: - Member Rewriting

  private func rewriteMembers(_ memberBlock: MemberBlockSyntax, framework: TestFramework) -> MemberBlockSyntax {
    var newMembers = [MemberBlockItemSyntax]()
    var changed = false

    for member in memberBlock.members {
      if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
        let rewritten = rewriteFunction(funcDecl, framework: framework)
        if rewritten.description != funcDecl.description {
          newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
          changed = true
          continue
        }
      } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
        let rewritten = rewriteProperty(varDecl)
        if rewritten.description != varDecl.description {
          newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
          changed = true
          continue
        }
      } else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
        let rewritten = removeExplicitACL(from: initDecl, keyword: \.initKeyword)
        if rewritten.description != initDecl.description {
          newMembers.append(member.with(\.decl, DeclSyntax(rewritten)))
          changed = true
          continue
        }
      }
      newMembers.append(member)
    }

    guard changed else { return memberBlock }
    return memberBlock.with(\.members, MemberBlockItemListSyntax(newMembers))
  }

  private func rewriteFunction(_ funcDecl: FunctionDeclSyntax, framework: TestFramework) -> FunctionDeclSyntax {
    let modifiers = funcDecl.modifiers

    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) }) { return funcDecl }
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) { return funcDecl }
    if funcDecl.attributes.attribute(named: "objc") != nil { return funcDecl }
    if hasDisabledPrefix(funcDecl.name.text) { return funcDecl }

    let isTest = isTestFunction(funcDecl, framework: framework)

    if isTest {
      if framework == .xcTest,
        modifiers.contains(where: {
          $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate)
        })
      {
        return funcDecl
      }
      return removeExplicitACL(from: funcDecl, keyword: \.funcKeyword)
    } else {
      if modifiers.contains(where: {
        $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate)
      }) {
        return funcDecl
      }
      return ensurePrivate(on: funcDecl, keyword: \.funcKeyword)
    }
  }

  private func rewriteProperty(_ varDecl: VariableDeclSyntax) -> VariableDeclSyntax {
    let modifiers = varDecl.modifiers
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) { return varDecl }
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) }) { return varDecl }
    if varDecl.attributes.attribute(named: "objc") != nil { return varDecl }
    if modifiers.contains(where: {
      $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate)
    }) { return varDecl }

    return ensurePrivate(on: varDecl, keyword: \.bindingSpecifier)
  }

  // MARK: - Test Function Detection

  private func isTestFunction(_ funcDecl: FunctionDeclSyntax, framework: TestFramework) -> Bool {
    if funcDecl.hasAttribute("Test", inModule: "Testing") { return true }
    if framework == .xcTest {
      return funcDecl.name.text.hasPrefix("test")
        && funcDecl.signature.parameterClause.parameters.isEmpty
        && funcDecl.signature.returnClause == nil
    }
    return false
  }

  // MARK: - Access Control Helpers

  private static let aclKeywords: Set<Keyword> = [.public, .private, .fileprivate, .internal, .package]

  private func removePublicModifier<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keyword: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard let publicMod = decl.modifiers.first(where: { $0.name.tokenKind == .keyword(.public) })
    else { return decl }

    diagnose(.removePublicFromTestType, on: publicMod.name)
    return decl.removingModifiers([.public], keyword: keyword)
  }

  private func removeExplicitACL<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keyword: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard let aclMod = decl.modifiers.first(where: {
      if case .keyword(let kw) = $0.name.tokenKind { return Self.aclKeywords.contains(kw) && kw != .internal }
      return false
    }) else { return decl }

    diagnose(.removeACLFromTestMethod, on: aclMod.name)

    guard case .keyword(let kwToRemove) = aclMod.name.tokenKind else { return decl }
    return decl.removingModifiers([kwToRemove], keyword: keyword)
  }

  private func ensurePrivate<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    on decl: Decl,
    keyword: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    if let aclMod = decl.modifiers.first(where: {
      if case .keyword(let kw) = $0.name.tokenKind { return Self.aclKeywords.contains(kw) }
      return false
    }) {
      diagnose(.makePrivate, on: aclMod.name)
      var result = decl
      var newModifiers = Array(result.modifiers)
      if let idx = newModifiers.firstIndex(where: { $0.id == aclMod.id }) {
        newModifiers[idx] = newModifiers[idx].with(\.name,
          .keyword(.private, leadingTrivia: aclMod.name.leadingTrivia, trailingTrivia: aclMod.name.trailingTrivia))
      }
      result.modifiers = DeclModifierListSyntax(newModifiers)
      return result
    }

    diagnose(.makePrivate, on: decl[keyPath: keyword])
    var result = decl
    var pm = DeclModifierSyntax(name: .keyword(.private, trailingTrivia: .space))
    pm.leadingTrivia = result[keyPath: keyword].leadingTrivia
    result[keyPath: keyword] = result[keyPath: keyword].with(\.leadingTrivia, [])
    var newModifiers = Array(result.modifiers)
    newModifiers.insert(pm, at: 0)
    result.modifiers = DeclModifierListSyntax(newModifiers)
    return result
  }
}

extension Finding.Message {
  fileprivate static let removePublicFromTestType: Finding.Message =
    "remove 'public' from test suite type"
  fileprivate static let removeACLFromTestMethod: Finding.Message =
    "remove explicit access control from test method"
  fileprivate static let makePrivate: Finding.Message =
    "make test helper 'private'"
}
