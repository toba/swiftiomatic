import SwiftSyntax

/// Remove immediately-invoked closures containing a single expression.
///
/// A closure that is immediately called and contains only a single expression or return
/// statement can be replaced with just the expression.
///
/// For example: `let x = { return 42 }()` → `let x = 42`
/// And: `let x = { someValue }()` → `let x = someValue`
///
/// This rule does NOT fire when the closure captures variables, has parameters, or
/// contains multiple statements.
///
/// Lint: If a redundant immediately-invoked closure is found, a lint warning is raised.
@_spi(Rules)
public final class RedundantClosure: SyntaxLintRule {

  public override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    // Must be a call with no arguments: `{ ... }()`
    guard node.arguments.isEmpty,
      node.trailingClosure == nil,
      let closure = node.calledExpression.as(ClosureExprSyntax.self)
    else {
      return .visitChildren
    }

    // Must have no parameters or capture list.
    guard closure.signature == nil else {
      return .visitChildren
    }

    let statements = closure.statements

    // Single expression statement.
    if statements.count == 1, let item = statements.first,
      item.item.is(ExprSyntax.self)
    {
      diagnose(.removeRedundantClosure, on: closure)
      return .skipChildren
    }

    // Single return statement with an expression.
    if statements.count == 1, let item = statements.first,
      let returnStmt = item.item.as(StmtSyntax.self)?.as(ReturnStmtSyntax.self),
      returnStmt.expression != nil
    {
      diagnose(.removeRedundantClosure, on: closure)
      return .skipChildren
    }

    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantClosure: Finding.Message =
    "remove immediately-invoked closure; use the expression directly"
}
