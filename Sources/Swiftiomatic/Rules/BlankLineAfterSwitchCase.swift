import SwiftSyntax

/// Insert a blank line after multiline switch case bodies.
///
/// When a switch case body spans multiple statements, a blank line after it improves readability
/// by visually separating it from the next case. Single-statement cases do not require blank lines.
/// The last case in a switch is never followed by a blank line (the closing brace provides
/// visual separation).
///
/// Lint: If a multiline case body is not followed by a blank line, a lint warning is raised.
///       If the last case is followed by a blank line before `}`, a lint warning is raised.
///
/// Format: Blank lines are inserted after multiline cases and removed after the last case.
@_spi(Rules)
public final class BlankLineAfterSwitchCase: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard var switchExpr = visited.as(SwitchExprSyntax.self) else { return visited }

    let cases = Array(switchExpr.cases)
    guard !cases.isEmpty else { return visited }

    var modifiedCases = cases
    var modified = false

    // Insert blank lines after multiline non-last cases.
    for i in 0..<(cases.count - 1) {
      guard case .switchCase(let switchCase) = cases[i],
        switchCase.statements.count > 1
      else { continue }

      let nextIndex = i + 1
      guard !hasBlankLine(in: cases[nextIndex].leadingTrivia) else { continue }

      diagnose(.insertBlankLineAfterCase, on: switchCase.label)
      modifiedCases[nextIndex] = addLeadingNewline(to: modifiedCases[nextIndex])
      modified = true
    }

    if modified {
      switchExpr.cases = SwitchCaseListSyntax(modifiedCases)
    }

    // Remove blank line before closing brace after last case.
    if hasBlankLine(in: switchExpr.rightBrace.leadingTrivia) {
      diagnose(.removeBlankLineBeforeClosingBrace, on: switchExpr.rightBrace)
      switchExpr.rightBrace = removeExtraNewlines(from: switchExpr.rightBrace)
      modified = true
    }

    return modified ? ExprSyntax(switchExpr) : visited
  }

  private func hasBlankLine(in trivia: Trivia) -> Bool {
    let newlineCount = trivia.pieces.reduce(0) { count, piece in
      switch piece {
      case .newlines(let n): count + n
      default: count
      }
    }
    return newlineCount >= 2
  }

  private func addLeadingNewline(to element: SwitchCaseListSyntax.Element) -> SwitchCaseListSyntax.Element {
    switch element {
    case .switchCase(var switchCase):
      switchCase.leadingTrivia = .newline + switchCase.leadingTrivia
      return .switchCase(switchCase)
    case .ifConfigDecl(var ifConfig):
      ifConfig.leadingTrivia = .newline + ifConfig.leadingTrivia
      return .ifConfigDecl(ifConfig)
    }
  }

  private func removeExtraNewlines(from token: TokenSyntax) -> TokenSyntax {
    let pieces = token.leadingTrivia.pieces.map { piece -> TriviaPiece in
      switch piece {
      case .newlines(let n) where n > 1: .newlines(1)
      default: piece
      }
    }
    return token.with(\.leadingTrivia, Trivia(pieces: pieces))
  }
}

extension Finding.Message {
  fileprivate static let insertBlankLineAfterCase: Finding.Message =
    "insert blank line after multiline switch case"

  fileprivate static let removeBlankLineBeforeClosingBrace: Finding.Message =
    "remove blank line before closing brace"
}
