import SwiftSyntax

/// Flag `throws` on functions that contain no `throw` or `try` expressions.
///
/// If a function is marked `throws` but its body never uses `throw` or `try`, the `throws`
/// is likely unnecessary.
///
/// This rule is opt-in because some functions are intentionally throwing for protocol
/// conformance or future-proofing even if they don't currently throw.
///
/// Lint: If a `throws` function has no `throw` or `try` in its body, a lint warning is raised.
@_spi(Rules)
public final class RedundantThrows: SyntaxLintRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let effectSpecifiers = node.signature.effectSpecifiers,
      effectSpecifiers.throwsClause != nil,
      let body = node.body
    else {
      return .visitChildren
    }

    if !containsThrowOrTry(body) {
      diagnose(.removeRedundantThrows, on: effectSpecifiers.throwsClause!)
    }

    return .skipChildren
  }

  /// Returns `true` if the syntax tree contains a `throw` statement or `try` expression,
  /// stopping at nested function/closure boundaries.
  private func containsThrowOrTry(_ node: some SyntaxProtocol) -> Bool {
    for child in node.children(viewMode: .sourceAccurate) {
      if child.is(FunctionDeclSyntax.self) || child.is(ClosureExprSyntax.self) {
        continue
      }
      if child.is(ThrowStmtSyntax.self) || child.is(TryExprSyntax.self) {
        return true
      }
      if containsThrowOrTry(child) {
        return true
      }
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantThrows: Finding.Message =
    "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"
}
