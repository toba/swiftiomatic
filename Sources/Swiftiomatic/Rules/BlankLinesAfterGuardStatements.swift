import SwiftSyntax

/// Remove blank lines between consecutive guard statements and insert a blank line after
/// the last guard.
///
/// Guard blocks at the top of a function form a precondition section. Keeping them tight
/// (no blank lines between them) and separated from the body (one blank line after) improves
/// readability. Comments between guards break the "consecutive" chain — each guard followed
/// by a comment gets its own trailing blank line.
///
/// Lint: If there are blank lines between consecutive guards, or no blank line after the
///       last guard before other code, a lint warning is raised.
///
/// Format: Blank lines between consecutive guards are removed. A blank line is inserted
///         after the last guard when followed by non-guard code.
@_spi(Rules)
public final class BlankLinesAfterGuardStatements: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
    let visited = super.visit(node)
    let originalStatements = Array(visited.statements)
    var statements = originalStatements
    var modified = false

    for i in 0..<originalStatements.count {
      guard originalStatements[i].item.is(GuardStmtSyntax.self) else { continue }

      let nextIndex = i + 1
      guard nextIndex < originalStatements.count else { continue }

      let nextStmt = originalStatements[nextIndex]
      let nextIsConsecutiveGuard =
        nextStmt.item.is(GuardStmtSyntax.self) && !nextStmt.leadingTrivia.hasAnyComments

      if nextIsConsecutiveGuard {
        // Remove blank lines between consecutive guards.
        guard nextStmt.leadingTrivia.hasBlankLine else { continue }
        diagnose(.removeBlankLineBetweenGuards, on: nextStmt.item)
        var modifiedNext = nextStmt
        modifiedNext.leadingTrivia = nextStmt.leadingTrivia.replacingFirstNewlines(with: 1)
        statements[nextIndex] = modifiedNext
        modified = true
      } else {
        // Ensure blank line after last guard in a run.
        guard !nextStmt.leadingTrivia.hasBlankLine else { continue }
        diagnose(.insertBlankLineAfterGuard, on: originalStatements[i].item)
        var modifiedNext = nextStmt
        modifiedNext.leadingTrivia = .newline + nextStmt.leadingTrivia
        statements[nextIndex] = modifiedNext
        modified = true
      }
    }

    guard modified else { return visited }
    var result = visited
    result.statements = CodeBlockItemListSyntax(statements)
    return result
  }
}

extension Finding.Message {
  fileprivate static let removeBlankLineBetweenGuards: Finding.Message =
    "remove blank line between consecutive guard statements"

  fileprivate static let insertBlankLineAfterGuard: Finding.Message =
    "insert blank line after guard statement"
}
