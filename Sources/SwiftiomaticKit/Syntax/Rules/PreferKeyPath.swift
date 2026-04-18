import SwiftSyntax

/// Convert trivial `map { $0.foo }` closures to keyPath-based syntax.
///
/// When a closure's only expression is a property access on `$0`, the closure can be
/// replaced with a keyPath expression: `map(\.foo)`. This is more concise and expressive.
///
/// Applies to `map`, `flatMap`, `compactMap`, `allSatisfy`, `filter`, and `contains(where:)`.
///
/// Only fires for simple property chains (not method calls, subscripts, or complex expressions).
///
/// Lint: A trivial `{ $0.property }` closure raises a warning.
///
/// Format: The closure is replaced with a keyPath expression.
final class PreferKeyPath: SyntaxFormatRule {
  static let defaultHandling: RuleHandling = .off

  private static let eligibleMethods: Set<String> = [
    "map", "flatMap", "compactMap", "allSatisfy", "filter", "contains",
  ]

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard let callNode = visited.as(FunctionCallExprSyntax.self) else { return visited }

    // Must be a method call (member access)
    guard let memberAccess = callNode.calledExpression.as(MemberAccessExprSyntax.self) else {
      return visited
    }

    let methodName = memberAccess.declName.baseName.text
    guard Self.eligibleMethods.contains(methodName) else {
      return visited
    }

    // Handle `contains(where:)` form
    if methodName == "contains" {
      return handleContainsWhere(callNode, memberAccess: memberAccess) ?? visited
    }

    // Handle trailing closure: map { $0.foo }
    // Skip multiple trailing closures (can't use keyPath with those)
    if let closure = callNode.trailingClosure,
      callNode.additionalTrailingClosures.isEmpty,
      let chain = extractPropertyChain(from: closure)
    {
      diagnose(.preferKeyPath(method: methodName), on: closure)

      let keyPath = buildKeyPath(from: chain)
      let arg = LabeledExprSyntax(expression: ExprSyntax(keyPath))

      // Strip trailing trivia from calledExpression (space before trailing closure)
      var calledExpr = callNode.calledExpression
      calledExpr.trailingTrivia = []

      let newCall = FunctionCallExprSyntax(
        calledExpression: calledExpr,
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([arg]),
        rightParen: .rightParenToken()
      )

      var result = ExprSyntax(newCall)
      result.leadingTrivia = node.leadingTrivia
      result.trailingTrivia = node.trailingTrivia
      return result
    }

    // Handle parenthesized closure: map({ $0.foo })
    if callNode.arguments.count == 1,
      let firstArg = callNode.arguments.first,
      firstArg.label == nil,
      let closureExpr = firstArg.expression.as(ClosureExprSyntax.self),
      let chain = extractPropertyChain(from: closureExpr)
    {
      diagnose(.preferKeyPath(method: methodName), on: firstArg.expression)

      let keyPath = buildKeyPath(from: chain)
      let newArg = firstArg.with(\.expression, ExprSyntax(keyPath))
      let newCall = callNode.with(\.arguments, LabeledExprListSyntax([newArg]))

      var result = ExprSyntax(newCall)
      result.leadingTrivia = node.leadingTrivia
      result.trailingTrivia = node.trailingTrivia
      return result
    }

    return visited
  }

  /// Handles `contains(where: { $0.foo })` → `contains(where: \.foo)`
  private func handleContainsWhere(
    _ callNode: FunctionCallExprSyntax,
    memberAccess: MemberAccessExprSyntax
  ) -> ExprSyntax? {
    guard let firstArg = callNode.arguments.first,
      firstArg.label?.text == "where",
      let closureExpr = firstArg.expression.as(ClosureExprSyntax.self),
      let chain = extractPropertyChain(from: closureExpr)
    else {
      return nil
    }

    diagnose(.preferKeyPath(method: "contains(where:)"), on: firstArg.expression)

    let keyPath = buildKeyPath(from: chain)
    let newArg = firstArg.with(
      \.expression,
      ExprSyntax(keyPath)
        .with(\.leadingTrivia, firstArg.expression.leadingTrivia)
        .with(\.trailingTrivia, firstArg.expression.trailingTrivia)
    )
    return ExprSyntax(callNode.with(\.arguments, LabeledExprListSyntax([newArg])))
  }

  /// Extracts the property chain from a `{ $0.foo.bar }` closure, returning `["foo", "bar"]`.
  private func extractPropertyChain(from closure: ClosureExprSyntax) -> [String]? {
    // Must have no explicit parameters (uses $0 shorthand)
    guard closure.signature == nil else { return nil }

    // Must have exactly one statement
    guard closure.statements.count == 1,
      let onlyItem = closure.statements.first,
      let expr = onlyItem.item.as(ExprSyntax.self)
    else {
      return nil
    }

    return extractChain(expr)
  }

  /// Recursively extracts property names from a `$0.a.b.c` chain.
  private func extractChain(_ expr: ExprSyntax) -> [String]? {
    guard let memberAccess = expr.as(MemberAccessExprSyntax.self),
      let base = memberAccess.base
    else {
      return nil
    }

    let name = memberAccess.declName.baseName.text

    if let ref = base.as(DeclReferenceExprSyntax.self), ref.baseName.text == "$0" {
      return [name]
    }

    guard var chain = extractChain(base) else { return nil }
    chain.append(name)
    return chain
  }

  /// Builds a `KeyPathExprSyntax` from a property chain like `["foo", "bar"]` → `\.foo.bar`.
  private func buildKeyPath(from chain: [String]) -> KeyPathExprSyntax {
    let components = chain.map { name in
      KeyPathComponentSyntax(
        period: .periodToken(),
        component: .property(
          KeyPathPropertyComponentSyntax(
            declName: DeclReferenceExprSyntax(baseName: .identifier(name))
          ))
      )
    }

    return KeyPathExprSyntax(
      backslash: .backslashToken(),
      components: KeyPathComponentListSyntax(components)
    )
  }
}

extension Finding.Message {
  fileprivate static func preferKeyPath(method: String) -> Finding.Message {
    "use keyPath expression instead of closure in '\(method)'"
  }
}
