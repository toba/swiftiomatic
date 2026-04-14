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
@_spi(Rules)
public final class RedundantViewBuilder: SyntaxLintRule {

  /// Identifies this rule as being opt-in. This rule requires SwiftUI context and may produce
  /// false positives in codebases that use custom result builders named `ViewBuilder`.
  public override class var isOptIn: Bool { true }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let viewBuilderAttr = findViewBuilderAttribute(in: node.attributes) else {
      return .visitChildren
    }

    // Must be a computed property with an accessor block.
    guard node.bindings.count == 1,
      let binding = node.bindings.first,
      let accessorBlock = binding.accessorBlock
    else {
      return .visitChildren
    }

    // Check for single-expression getter.
    if case .getter(let body) = accessorBlock.accessors,
      isSingleExpression(body)
    {
      diagnose(.removeRedundantViewBuilder, on: viewBuilderAttr)
    }

    return .visitChildren
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let viewBuilderAttr = findViewBuilderAttribute(in: node.attributes) else {
      return .visitChildren
    }

    // Must have a body (not a protocol requirement).
    guard let body = node.body else {
      return .visitChildren
    }

    if isSingleExpression(body.statements) {
      diagnose(.removeRedundantViewBuilder, on: viewBuilderAttr)
    }

    return .visitChildren
  }

  /// Returns the `@ViewBuilder` attribute if present in the list, or `nil`.
  private func findViewBuilderAttribute(in attributes: AttributeListSyntax) -> AttributeSyntax? {
    for element in attributes {
      guard case .attribute(let attr) = element,
        let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
        name == "ViewBuilder"
      else {
        continue
      }
      return attr
    }
    return nil
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
