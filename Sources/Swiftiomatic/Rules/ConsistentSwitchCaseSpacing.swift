import SwiftSyntax

/// Ensure consistent blank-line spacing among all cases in a switch statement.
///
/// When some cases in a switch are separated by blank lines and others aren't, the
/// inconsistency looks sloppy. This rule normalizes to whichever style is used by
/// the majority of cases: if more cases have blank lines, missing ones are added;
/// if fewer do, extra ones are removed. The last case is excluded (it's always
/// followed by `}`).
///
/// Lint: If any case's spacing is inconsistent with the majority, a lint warning is raised.
///
/// Format: Blank lines are added or removed to make spacing consistent.
@_spi(Rules)
public final class ConsistentSwitchCaseSpacing: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard var switchExpr = visited.as(SwitchExprSyntax.self) else { return visited }

    let cases = Array(switchExpr.cases)
    // Need at least 2 cases (last case is excluded from spacing decisions).
    guard cases.count >= 2 else { return visited }

    // Count cases with/without blank lines (exclude last case).
    var withBlank = 0
    var withoutBlank = 0
    for i in 0..<(cases.count - 1) {
      let nextTrivia = cases[i + 1].leadingTrivia
      if hasBlankLine(in: nextTrivia) {
        withBlank += 1
      } else {
        withoutBlank += 1
      }
    }

    // Majority wins; ties favor blank lines.
    let shouldHaveBlankLines = withBlank >= withoutBlank

    var modifiedCases = cases
    var modified = false

    for i in 0..<(cases.count - 1) {
      let nextIndex = i + 1
      let nextTrivia = cases[nextIndex].leadingTrivia
      let currentlyHasBlank = hasBlankLine(in: nextTrivia)

      if shouldHaveBlankLines && !currentlyHasBlank {
        // Add blank line.
        diagnose(.addBlankLineForConsistency, on: cases[nextIndex])
        modifiedCases[nextIndex] = addLeadingNewline(to: modifiedCases[nextIndex])
        modified = true
      } else if !shouldHaveBlankLines && currentlyHasBlank {
        // Remove blank line.
        diagnose(.removeBlankLineForConsistency, on: cases[nextIndex])
        modifiedCases[nextIndex] = removeBlankLine(from: modifiedCases[nextIndex])
        modified = true
      }
    }

    guard modified else { return visited }
    switchExpr.cases = SwitchCaseListSyntax(modifiedCases)
    return ExprSyntax(switchExpr)
  }

  private func hasBlankLine(in trivia: Trivia) -> Bool {
    var newlines = 0
    for piece in trivia.pieces {
      if case .newlines(let n) = piece { newlines += n }
      else if piece.isSpaceOrTab { continue }
      else { break }
    }
    return newlines >= 2
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

  private func removeBlankLine(from element: SwitchCaseListSyntax.Element) -> SwitchCaseListSyntax.Element {
    switch element {
    case .switchCase(var switchCase):
      switchCase.leadingTrivia = reducedTrivia(switchCase.leadingTrivia)
      return .switchCase(switchCase)
    case .ifConfigDecl(var ifConfig):
      ifConfig.leadingTrivia = reducedTrivia(ifConfig.leadingTrivia)
      return .ifConfigDecl(ifConfig)
    }
  }

  /// Reduce the first `.newlines(N)` piece to `.newlines(1)`.
  private func reducedTrivia(_ trivia: Trivia) -> Trivia {
    var pieces = Array(trivia.pieces)
    for (i, piece) in pieces.enumerated() {
      if case .newlines(let n) = piece, n > 1 {
        pieces[i] = .newlines(1)
        return Trivia(pieces: pieces)
      }
    }
    return trivia
  }
}

extension Finding.Message {
  fileprivate static let addBlankLineForConsistency: Finding.Message =
    "add blank line between switch cases for consistency"

  fileprivate static let removeBlankLineForConsistency: Finding.Message =
    "remove blank line between switch cases for consistency"
}
