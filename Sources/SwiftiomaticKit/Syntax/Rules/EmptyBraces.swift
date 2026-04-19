import SwiftSyntax

/// Remove whitespace inside empty braces.
///
/// Empty brace pairs should have no whitespace between them: `{}` instead of `{ }` or
/// multi-line empty bodies. Braces containing comments are left unchanged.
///
/// Lint: If empty braces contain whitespace, a lint warning is raised.
///
/// Format: The whitespace is removed, collapsing the braces to `{}`.
final class EmptyBraces: RewriteSyntaxRule {

  override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
    var result = node
    if result.statements.isEmpty {
      result = collapseIfNeeded(result, leftBrace: \.leftBrace, rightBrace: \.rightBrace)
    }
    return result
  }

  override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
    var result = node
    if result.members.isEmpty {
      result = collapseIfNeeded(result, leftBrace: \.leftBrace, rightBrace: \.rightBrace)
    }
    return result
  }

  override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    var result = node
    if result.statements.isEmpty, result.signature == nil {
      result = collapseIfNeeded(result, leftBrace: \.leftBrace, rightBrace: \.rightBrace)
    }
    return ExprSyntax(result)
  }

  /// Collapses whitespace between empty braces if no comments are present between them.
  private func collapseIfNeeded<Node: SyntaxProtocol>(
    _ node: Node,
    leftBrace: WritableKeyPath<Node, TokenSyntax>,
    rightBrace: WritableKeyPath<Node, TokenSyntax>
  ) -> Node {
    let left = node[keyPath: leftBrace]
    let right = node[keyPath: rightBrace]

    // Don't collapse if there are comments between the braces.
    if left.trailingTrivia.hasAnyComments || right.leadingTrivia.hasAnyComments {
      return node
    }

    // Check if there is any whitespace/newlines to remove.
    let hasTrailingWhitespace = !left.trailingTrivia.isEmpty
    let hasLeadingWhitespace = !right.leadingTrivia.isEmpty

    guard hasTrailingWhitespace || hasLeadingWhitespace else { return node }

    diagnose(.removeWhitespaceInEmptyBraces, on: left)

    var result = node
    if hasTrailingWhitespace {
      result[keyPath: leftBrace] = left.with(\.trailingTrivia, [])
    }
    if hasLeadingWhitespace {
      result[keyPath: rightBrace] = right.with(\.leadingTrivia, [])
    }
    return result
  }
}

extension Finding.Message {
  fileprivate static let removeWhitespaceInEmptyBraces: Finding.Message =
    "remove whitespace inside empty braces"
}
