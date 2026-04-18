import SwiftSyntax

/// Remove `@ViewBuilder` when the body is a single expression.
///
/// `@ViewBuilder` is unnecessary on computed properties and functions that return a single
/// view expression, since Swift can infer the return type without the result builder.
///
/// This rule flags `@ViewBuilder` on:
/// - Computed properties with a single-expression getter
/// - Functions with a single-expression body
///
/// It does NOT flag `@ViewBuilder` on:
/// - Closures (parameters)
/// - Bodies with multiple statements, `if/else`, `switch`, or `ForEach`
/// - Protocol requirements
///
/// Lint: If a redundant `@ViewBuilder` is found, a lint warning is raised.
///
/// Format: The redundant `@ViewBuilder` attribute is removed.
@_spi(Rules)
public final class RedundantViewBuilder: SyntaxFormatRule {
  public override class var group: ConfigGroup? { .removeRedundant }

  /// Identifies this rule as being opt-in. This rule requires SwiftUI context and may produce
  /// false positives in codebases that use custom result builders named `ViewBuilder`.
  public override class var isOptIn: Bool { true }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    guard let viewBuilderAttr = node.attributes.attribute(named: "ViewBuilder") else {
      return DeclSyntax(node)
    }

    // Must be a computed property with an accessor block.
    guard node.bindings.count == 1,
      let binding = node.bindings.first,
      let accessorBlock = binding.accessorBlock
    else {
      return DeclSyntax(node)
    }

    // Check for single-expression getter.
    guard case .getter(let body) = accessorBlock.accessors,
      isSingleExpression(body)
    else {
      return DeclSyntax(node)
    }

    diagnose(.removeRedundantViewBuilder, on: viewBuilderAttr)
    var result = node
    let savedTrivia = viewBuilderAttr.leadingTrivia
    result.attributes = node.attributes.removing(named: "ViewBuilder")
    // Transfer the removed attribute's leading trivia to the next token.
    if result.attributes.isEmpty {
      result.bindingSpecifier.leadingTrivia = savedTrivia
    }
    return DeclSyntax(result)
  }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard let viewBuilderAttr = node.attributes.attribute(named: "ViewBuilder") else {
      return DeclSyntax(node)
    }

    // Must have a body (not a protocol requirement).
    guard let body = node.body else {
      return DeclSyntax(node)
    }

    guard isSingleExpression(body.statements) else {
      return DeclSyntax(node)
    }

    diagnose(.removeRedundantViewBuilder, on: viewBuilderAttr)
    var result = node
    let savedTrivia = viewBuilderAttr.leadingTrivia
    result.attributes = node.attributes.removing(named: "ViewBuilder")
    // Transfer the removed attribute's leading trivia to the next token.
    if result.attributes.isEmpty {
      if result.modifiers.first != nil {
        result.modifiers[result.modifiers.startIndex].leadingTrivia = savedTrivia
      } else {
        result.funcKeyword.leadingTrivia = savedTrivia
      }
    }
    return DeclSyntax(result)
  }

  /// Returns `true` if the code block contains exactly one expression statement.
  private func isSingleExpression(_ statements: CodeBlockItemListSyntax) -> Bool {
    guard statements.count == 1 else { return false }
    guard let item = statements.first else { return false }
    // Must be a single expression, not a declaration or control flow statement.
    return item.item.is(ExprSyntax.self)
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantViewBuilder: Finding.Message =
    "remove '@ViewBuilder'; single-expression body does not need a result builder"
}
