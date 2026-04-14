import SwiftSyntax

/// Remove blank lines between consecutive import statements.
///
/// Import blocks should be compact — blank lines within the import section add visual noise
/// without aiding readability. This rule removes them while preserving linebreaks.
///
/// Lint: If there are blank lines between consecutive import statements, a lint warning is raised.
///
/// Format: The blank lines are removed.
@_spi(Rules)
public final class BlankLinesBetweenImports: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    let originalStatements = Array(node.statements)
    var statements = originalStatements
    var modified = false

    for i in 0..<originalStatements.count {
      guard originalStatements[i].item.is(ImportDeclSyntax.self) else { continue }

      let nextIndex = i + 1
      guard nextIndex < originalStatements.count,
        originalStatements[nextIndex].item.is(ImportDeclSyntax.self)
      else { continue }

      let nextStmt = originalStatements[nextIndex]
      let blanks = blankLineCount(in: nextStmt.leadingTrivia)
      guard blanks > 0 else { continue }

      diagnose(.removeBlankLineBetweenImports, on: nextStmt.item)
      statements[nextIndex] = withNewlineCount(nextStmt, count: 1)
      modified = true
    }

    guard modified else { return node }
    var result = node
    result.statements = CodeBlockItemListSyntax(statements)
    return result
  }

  /// Count blank lines before the first comment in the trivia.
  private func blankLineCount(in trivia: Trivia) -> Int {
    var newlines = 0
    for piece in trivia.pieces {
      if case .newlines(let n) = piece { newlines += n }
      else if piece.isSpaceOrTab { continue }
      else { break }
    }
    return max(0, newlines - 1)
  }

  /// Replace the first `.newlines` piece with exactly `count` newlines.
  private func withNewlineCount(_ statement: CodeBlockItemSyntax, count: Int) -> CodeBlockItemSyntax {
    var pieces = Array(statement.leadingTrivia.pieces)
    for (i, piece) in pieces.enumerated() {
      if case .newlines = piece {
        pieces[i] = .newlines(count)
        var result = statement
        result.leadingTrivia = Trivia(pieces: pieces)
        return result
      }
    }
    return statement
  }
}

extension Finding.Message {
  fileprivate static let removeBlankLineBetweenImports: Finding.Message =
    "remove blank line between import statements"
}
