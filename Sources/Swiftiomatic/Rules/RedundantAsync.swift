import SwiftSyntax

/// Flag `async` on functions that contain no `await` expressions.
///
/// If a function is marked `async` but its body never uses `await`, the `async` is likely
/// unnecessary. Removing it simplifies the API and removes the requirement for callers
/// to use `await`.
///
/// This rule is opt-in because some functions are intentionally async for protocol
/// conformance or future-proofing even if they don't currently await.
///
/// Lint: If an `async` function has no `await` in its body, a lint warning is raised.
@_spi(Rules)
public final class RedundantAsync: SyntaxLintRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let effectSpecifiers = node.signature.effectSpecifiers,
      let throwsClause = effectSpecifiers.asyncSpecifier,
      throwsClause.tokenKind == .keyword(.async),
      let body = node.body
    else {
      return .visitChildren
    }

    // Check if the body contains any `await` expression.
    if !containsAwait(body) {
      diagnose(.removeRedundantAsync, on: throwsClause)
    }

    // Don't visit children — nested functions have their own async context.
    return .skipChildren
  }

  /// Returns `true` if the syntax tree contains an `await` expression,
  /// stopping at nested function/closure boundaries.
  private func containsAwait(_ node: some SyntaxProtocol) -> Bool {
    for child in node.children(viewMode: .sourceAccurate) {
      // Stop at nested function/closure boundaries — they have their own async context.
      if child.is(FunctionDeclSyntax.self) || child.is(ClosureExprSyntax.self) {
        continue
      }

      if let awaitExpr = child.as(AwaitExprSyntax.self) {
        _ = awaitExpr  // suppress unused warning
        return true
      }

      if containsAwait(child) {
        return true
      }
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantAsync: Finding.Message =
    "function is 'async' but contains no 'await'; consider removing 'async'"
}
