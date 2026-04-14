import SwiftSyntax

/// Remove `Self.` prefix in static context where the type is already inferred.
///
/// Inside a static method or static computed property, `Self.` is redundant when accessing
/// other static members of the same type.
///
/// For example, inside `static func make()`, writing `Self.defaultValue` can be simplified
/// to just `defaultValue`.
///
/// Lint: If a redundant `Self.` is found in a static context, a lint warning is raised.
@_spi(Rules)
public final class RedundantStaticSelf: SyntaxLintRule {

  /// Identifies this rule as opt-in. Removing `Self.` can change semantics in contexts
  /// with shadowing, so this requires explicit opt-in.
  public override class var isOptIn: Bool { true }

  public override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
    // Check if the base is `Self`.
    guard let base = node.base,
      let declRef = base.as(DeclReferenceExprSyntax.self),
      declRef.baseName.tokenKind == .keyword(.Self)
    else {
      return .visitChildren
    }

    // Only flag if we're inside a static context.
    guard isInStaticContext(node) else {
      return .visitChildren
    }

    diagnose(.removeRedundantStaticSelf, on: base)
    return .visitChildren
  }

  /// Returns `true` if the node is inside a static method or static computed property.
  private func isInStaticContext(_ node: some SyntaxProtocol) -> Bool {
    var current = node.parent
    while let parent = current {
      // Check for static/class modifier on functions.
      if let funcDecl = parent.as(FunctionDeclSyntax.self) {
        return funcDecl.modifiers.contains(anyOf: [.static, .class])
      }
      // Check for static/class modifier on variables.
      if let varDecl = parent.as(VariableDeclSyntax.self) {
        return varDecl.modifiers.contains(anyOf: [.static, .class])
      }
      // Check for static subscripts.
      if let subDecl = parent.as(SubscriptDeclSyntax.self) {
        return subDecl.modifiers.contains(anyOf: [.static, .class])
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
}

extension Finding.Message {
  fileprivate static let removeRedundantStaticSelf: Finding.Message =
    "remove redundant 'Self.' in static context"
}
