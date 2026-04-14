import SwiftSyntax

/// Inline conditional statement bodies are wrapped onto new lines.
///
/// Single-line `if`, `else`, and `guard` bodies are expanded so the body content
/// starts on its own line with proper indentation.
///
/// Lint: A single-line conditional body raises a warning.
///
/// Format: The body is wrapped onto a new line with indentation.
@_spi(Rules)
public final class WrapConditionalBodies: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  /// Tracks the current body indentation for nested inline structures.
  private var currentIndent = ""

  /// Tracks the base indentation for if/else-if chains so that `else if` bodies
  /// use the same base as the outermost `if`.
  private var chainBaseIndent: String?

  public override func visit(_ node: IfExprSyntax) -> ExprSyntax {
    let isElseIf = node.parent?.is(IfExprSyntax.self) == true

    let baseIndent: String
    if isElseIf, let chainIndent = chainBaseIndent {
      baseIndent = chainIndent
    } else {
      baseIndent = resolveIndent(from: node.ifKeyword.leadingTrivia)
    }

    let savedChainIndent = chainBaseIndent
    let savedIndent = currentIndent
    chainBaseIndent = baseIndent
    currentIndent = baseIndent + "    "
    defer {
      currentIndent = savedIndent
      chainBaseIndent = savedChainIndent
    }

    let needsBodyWrap = node.body.bodyNeedsWrapping
    if needsBodyWrap {
      diagnose(.wrapConditionalBody, on: node.body.leftBrace)
    }

    var result = node
    result.body.statements = visit(node.body.statements)
    if needsBodyWrap {
      result.body = result.body.wrappingBody(baseIndent: baseIndent)
    }

    if let elseBody = node.elseBody {
      switch elseBody {
      case .ifExpr(let nestedIf):
        result.elseBody = .ifExpr(visit(nestedIf).cast(IfExprSyntax.self))
      case .codeBlock(var block):
        let needsElseWrap = block.bodyNeedsWrapping
        if needsElseWrap {
          diagnose(.wrapConditionalBody, on: block.leftBrace)
        }
        block.statements = visit(block.statements)
        if needsElseWrap {
          block = block.wrappingBody(baseIndent: baseIndent)
        }
        result.elseBody = .codeBlock(block)
      }
    }

    return ExprSyntax(result)
  }

  public override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
    let baseIndent = resolveIndent(from: node.guardKeyword.leadingTrivia)

    let savedIndent = currentIndent
    currentIndent = baseIndent + "    "
    defer { currentIndent = savedIndent }

    let needsWrap = node.body.bodyNeedsWrapping
    if needsWrap {
      diagnose(.wrapConditionalBody, on: node.body.leftBrace)
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
  fileprivate static let wrapConditionalBody: Finding.Message =
    "wrap conditional body onto a new line"
}
