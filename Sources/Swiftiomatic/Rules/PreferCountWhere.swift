import SwiftSyntax

/// Prefer `count(where:)` over `filter(_:).count`.
///
/// The `count(where:)` method (Swift 6.0+) is more expressive and avoids allocating an
/// intermediate array just to count its elements.
///
/// Lint: Using `.filter { ... }.count` raises a warning suggesting `count(where:)`.
///
/// Format: `.filter { ... }.count` is replaced with `.count(where: { ... })`.
@_spi(Rules)
public final class PreferCountWhere: SyntaxFormatRule {

  public override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    // If .count is a method call (parent is FunctionCallExprSyntax with this as calledExpression),
    // skip — check on original node before visiting children.
    if let parent = node.parent?.as(FunctionCallExprSyntax.self),
      parent.calledExpression.id == ExprSyntax(node).id
    {
      return super.visit(node)
    }

    let visited = super.visit(node)
    guard let memberNode = visited.as(MemberAccessExprSyntax.self) else { return visited }

    // Match .count property access
    guard memberNode.declName.baseName.text == "count" else { return visited }

    // Base must be a .filter call
    guard let filterCall = memberNode.base?.as(FunctionCallExprSyntax.self),
      let filterAccess = filterCall.calledExpression.as(MemberAccessExprSyntax.self),
      filterAccess.declName.baseName.text == "filter"
    else {
      return visited
    }

    // Extract the closure (trailing or inline single arg)
    let closure: ClosureExprSyntax
    if let trailingClosure = filterCall.trailingClosure {
      closure = trailingClosure
    } else if filterCall.arguments.count == 1,
      let closureExpr = filterCall.arguments.first?.expression.as(ClosureExprSyntax.self)
    {
      closure = closureExpr
    } else {
      return visited
    }

    diagnose(.preferCountWhere, on: filterAccess.declName)

    // Build: <originalBase>.count(where: { ... })
    let countAccess = MemberAccessExprSyntax(
      base: filterAccess.base,
      period: filterAccess.period,
      declName: DeclReferenceExprSyntax(baseName: .identifier("count"))
    )

    let whereArg = LabeledExprSyntax(
      label: .identifier("where"),
      colon: .colonToken(trailingTrivia: .space),
      expression: ExprSyntax(
        closure
          .with(\.leadingTrivia, [])
          .with(\.trailingTrivia, [])
      )
    )

    let countCall = FunctionCallExprSyntax(
      calledExpression: ExprSyntax(countAccess),
      leftParen: .leftParenToken(),
      arguments: LabeledExprListSyntax([whereArg]),
      rightParen: .rightParenToken()
    )

    var result = ExprSyntax(countCall)
    result.leadingTrivia = node.leadingTrivia
    result.trailingTrivia = node.trailingTrivia
    return result
  }
}

extension Finding.Message {
  fileprivate static let preferCountWhere: Finding.Message =
    "prefer 'count(where:)' over 'filter(_:).count'"
}
