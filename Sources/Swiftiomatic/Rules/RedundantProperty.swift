import SwiftSyntax

/// Remove a property that is assigned and immediately returned on the next line.
///
/// When a `let` binding is followed immediately by a `return` of the same identifier,
/// the binding is unnecessary. The expression can be returned directly.
///
/// For example: `let result = expr; return result` → `return expr`.
///
/// This rule only fires when the variable is a simple `let` with one binding, no type
/// annotation, and the very next statement is `return <same identifier>`.
///
/// Lint: If a redundant property-then-return is found, a lint warning is raised.
@_spi(Rules)
public final class RedundantProperty: SyntaxLintRule {

  public override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
    let items = Array(node)

    for i in 0..<items.count - 1 {
      guard let varDecl = items[i].item.as(DeclSyntax.self)?.as(VariableDeclSyntax.self),
        varDecl.bindingSpecifier.tokenKind == .keyword(.let),
        varDecl.bindings.count == 1,
        let binding = varDecl.bindings.first,
        let identPattern = binding.pattern.as(IdentifierPatternSyntax.self),
        binding.typeAnnotation == nil,
        binding.initializer != nil
      else {
        continue
      }

      let name = identPattern.identifier.text

      guard let returnStmt = items[i + 1].item.as(StmtSyntax.self)?.as(ReturnStmtSyntax.self),
        let returnExpr = returnStmt.expression,
        let declRef = returnExpr.as(DeclReferenceExprSyntax.self),
        declRef.baseName.text == name,
        declRef.argumentNames == nil
      else {
        continue
      }

      diagnose(.removeRedundantProperty(name: name), on: varDecl.bindingSpecifier)
    }

    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantProperty(name: String) -> Finding.Message {
    "remove redundant '\(name)' property; return the expression directly"
  }
}
