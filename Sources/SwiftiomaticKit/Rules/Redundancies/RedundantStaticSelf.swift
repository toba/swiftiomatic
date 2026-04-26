import SwiftSyntax

/// Remove `Self.` prefix in static context where the type is already inferred.
///
/// Inside a static method or static computed property, `Self.` is redundant when accessing
/// other static members of the same type. For example, inside `static func make()`,
/// writing `Self.defaultValue` can be simplified to just `defaultValue`.
///
/// The rule preserves `Self` when:
/// - Used as an initializer: `Self()`, `Self.init()`
/// - Inside an instance method, getter, or initializer
/// - A parameter or local shadows the static member name
///
/// Lint: If a redundant `Self.` is found in a static context, a finding is raised.
///
/// Format: The `Self.` prefix is removed.
final class RedundantStaticSelf: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard let memberAccess = visited.as(MemberAccessExprSyntax.self) else {
      return visited
    }

    // Check if the base is `Self`.
    guard let base = memberAccess.base,
          let declRef = base.as(DeclReferenceExprSyntax.self),
          declRef.baseName.tokenKind == .keyword(.Self)
    else {
      return visited
    }

    // Don't remove `Self` when used as an initializer: `Self()` or `Self.init()`.
    if memberAccess.declName.baseName.tokenKind == .keyword(.`init`) {
      return visited
    }


    // Only remove if we're inside a static context.
    guard isInStaticContext(node) else {
      return visited
    }

    // Don't remove if a parameter or local variable shadows the member name.
    let memberName = memberAccess.declName.baseName.text
    if isShadowed(name: memberName, at: node) {
      return visited
    }

    diagnose(.removeRedundantStaticSelf, on: base)

    // Replace `Self.member` with just `member` — a DeclReferenceExprSyntax.
    var result = DeclReferenceExprSyntax(
      baseName: memberAccess.declName.baseName,
      argumentNames: memberAccess.declName.argumentNames
    )
    // Transfer leading trivia from `Self` to the replacement.
    result.leadingTrivia = declRef.leadingTrivia
    // Transfer trailing trivia from the member name.
    result.trailingTrivia = memberAccess.declName.baseName.trailingTrivia
    return ExprSyntax(result)
  }

  // MARK: - Static context detection

  /// Returns `true` if the node is inside a static method or static computed property.
  /// Nested functions inside a static context are still static (they can access static members).
  private func isInStaticContext(_ node: some SyntaxProtocol) -> Bool {
    var current = node.parent
    while let parent = current {
      // For functions: if static/class → yes. If a direct member (parent is MemberBlock) and
      // NOT static → this is an instance method. If nested (parent is CodeBlock), continue.
      if let funcDecl = parent.as(FunctionDeclSyntax.self) {
        if funcDecl.modifiers.contains(anyOf: [.static, .class]) {
          return true
        }
        // Direct member of a type — instance method, not static
        if funcDecl.parent?.is(MemberBlockItemSyntax.self) == true {
          return false
        }
        // Nested function — continue walking up
      }

      if let varDecl = parent.as(VariableDeclSyntax.self) {
        if varDecl.modifiers.contains(anyOf: [.static, .class]) {
          return true
        }
        if varDecl.parent?.is(MemberBlockItemSyntax.self) == true {
          return false
        }
      }

      if let subDecl = parent.as(SubscriptDeclSyntax.self) {
        if subDecl.modifiers.contains(anyOf: [.static, .class]) {
          return true
        }
        if subDecl.parent?.is(MemberBlockItemSyntax.self) == true {
          return false
        }
      }

      // Initializers are NOT static context — `Self.foo` in init is needed.
      if parent.is(InitializerDeclSyntax.self) {
        return false
      }

      // Stop at type boundaries — don't look past a struct/class/enum.
      if parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
        || parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self)
      {
        return false
      }
      current = parent.parent
    }
    return false
  }

  // MARK: - Shadowing detection

  /// Returns `true` if the given name is shadowed by a parameter or local variable
  /// in the enclosing scope.
  private func isShadowed(name: String, at node: some SyntaxProtocol) -> Bool {
    var current = node.parent
    while let parent = current {
      // Check function parameters
      if let funcDecl = parent.as(FunctionDeclSyntax.self) {
        for param in funcDecl.signature.parameterClause.parameters {
          let paramName = (param.secondName ?? param.firstName).text
          if paramName == name { return true }
        }
        return false  // Stop at the function boundary
      }
      // Check subscript parameters
      if let subDecl = parent.as(SubscriptDeclSyntax.self) {
        for param in subDecl.parameterClause.parameters {
          let paramName = (param.secondName ?? param.firstName).text
          if paramName == name { return true }
        }
        return false
      }
      // Stop at type boundaries
      if parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
        || parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self)
      {
        return false
      }
      current = parent.parent
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantStaticSelf: Finding.Message =
    "remove redundant 'Self.' in static context"
}
