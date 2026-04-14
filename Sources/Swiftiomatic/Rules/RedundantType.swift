import SwiftSyntax

/// Remove redundant type annotations when the type is obvious from the initializer.
///
/// A type annotation is redundant when it exactly matches what the compiler would infer,
/// such as `let x: Foo = Foo(...)` or `let x: Bool = true`.
///
/// This rule fires for:
/// - Constructor calls matching the annotation: `let x: Foo = Foo(...)` → `let x = Foo(...)`
/// - Boolean literals: `let x: Bool = true` → `let x = true`
/// - String literals: `let x: String = "hello"` → `let x = "hello"`
///
/// It does NOT fire for numeric literals (which could be Int, Double, Float, etc.) or
/// collection literals (which could be Array, Set, etc.).
///
/// Lint: If a redundant type annotation is found, a lint warning is raised.
@_spi(Rules)
public final class RedundantType: SyntaxLintRule {

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    for binding in node.bindings {
      guard let typeAnnotation = binding.typeAnnotation,
        let initializer = binding.initializer
      else {
        continue
      }

      let typeName = typeAnnotation.type.trimmedDescription

      if isRedundant(typeName: typeName, initializer: initializer.value) {
        diagnose(.removeRedundantType(typeName: typeName), on: typeAnnotation)
      }
    }
    return .visitChildren
  }

  /// Returns `true` if the type annotation is redundant given the initializer expression.
  private func isRedundant(typeName: String, initializer: ExprSyntax) -> Bool {
    // `let x: Foo = Foo(...)` or `let x: Foo = Foo.init(...)`
    if let funcCall = initializer.as(FunctionCallExprSyntax.self) {
      if let calledName = simpleTypeName(from: funcCall.calledExpression) {
        return calledName == typeName
      }
    }

    // `let x: Bool = true/false`
    if initializer.is(BooleanLiteralExprSyntax.self) {
      return typeName == "Bool"
    }

    // `let x: String = "..."`
    if initializer.is(StringLiteralExprSyntax.self) {
      return typeName == "String"
    }

    return false
  }

  /// Extracts the simple type name from a called expression, if it's a direct type reference.
  ///
  /// Returns `nil` for complex expressions like method calls, closures, etc.
  private func simpleTypeName(from expr: ExprSyntax) -> String? {
    // `Foo(...)` — DeclReferenceExpr with no argument names
    if let declRef = expr.as(DeclReferenceExprSyntax.self),
      declRef.argumentNames == nil
    {
      return declRef.baseName.text
    }

    // `Foo.init(...)` — MemberAccessExpr where declName is `init`
    if let memberAccess = expr.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.tokenKind == .keyword(.`init`),
      let base = memberAccess.base
    {
      return base.trimmedDescription
    }

    // `Module.Foo(...)` — MemberAccessExpr where declName is the type
    if let memberAccess = expr.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.tokenKind != .keyword(.`init`)
    {
      return memberAccess.trimmedDescription
    }

    return nil
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantType(typeName: String) -> Finding.Message {
    "remove redundant type annotation '\(typeName)'; it is obvious from the initializer"
  }
}
