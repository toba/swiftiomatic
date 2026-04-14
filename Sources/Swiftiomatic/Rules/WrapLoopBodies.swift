import SwiftSyntax

/// Inline loop bodies are wrapped onto new lines.
///
/// Single-line `for`, `while`, and `repeat` loop bodies are expanded so the body
/// content starts on its own line with proper indentation.
///
/// Lint: A single-line loop body raises a warning.
///
/// Format: The body is wrapped onto a new line with indentation.
@_spi(Rules)
public final class WrapLoopBodies: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  private var currentIndent = ""

  public override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.forKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapLoopBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }
    return StmtSyntax(result)
  }

  public override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.whileKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapLoopBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }
    return StmtSyntax(result)
  }

  public override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.repeatKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapLoopBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }
    return StmtSyntax(result)
  }

  private func resolveIndent(from trivia: Trivia) -> String {
    if trivia.containsNewlines { return trivia.indentation }
    return currentIndent
  }
}

extension Finding.Message {
  fileprivate static let wrapLoopBody: Finding.Message =
    "wrap loop body onto a new line"
}
