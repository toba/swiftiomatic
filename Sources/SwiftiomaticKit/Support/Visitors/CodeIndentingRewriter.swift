import SwiftSyntax

/// Rewrites leading trivia to indent or unindent a syntax subtree
///
/// Handles comments and nested AST nodes (e.g. a code block inside another
/// code block) by adjusting whitespace trivia on every token.
final class CodeIndentingRewriter: SyntaxRewriter {
  /// Direction and unit of indentation change
  enum IndentationStyle {
    /// Indent by a number of spaces
    case indentSpaces(Int)
    /// Unindent by a number of spaces
    case unindentSpaces(Int)
    /// Indent by a number of tabs
    case indentTabs(Int)
    /// Unindent by a number of tabs
    case unindentTabs(Int)
  }

  private let style: IndentationStyle
  private var isFirstToken = true

  /// Creates a rewriter with the given indentation style
  ///
  /// - Parameters:
  ///   - style: The indentation style to apply. Defaults to 4-space indent.
  init(style: IndentationStyle = .indentSpaces(4)) {
    self.style = style
  }

  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    defer { isFirstToken = false }
    return super.visit(
      token.with(
        \.leadingTrivia,
        Trivia(pieces: indentedTriviaPieces(for: token.leadingTrivia)),
      ),
    )
  }

  private func indentedTriviaPieces(for trivia: Trivia) -> [TriviaPiece] {
    switch style {
    case .indentSpaces(let number): indent(trivia: trivia, by: .spaces(number))
    case .indentTabs(let number): indent(trivia: trivia, by: .tabs(number))
    case .unindentSpaces(let number): unindent(trivia: trivia, by: .spaces(number))
    case .unindentTabs(let number): unindent(trivia: trivia, by: .tabs(number))
    }
  }

  private func indent(trivia: Trivia, by indentation: TriviaPiece) -> [TriviaPiece] {
    let indentedPieces = trivia.pieces.flatMap { piece in
      switch piece {
      case .newlines: [piece, indentation]
      default: [piece]
      }
    }
    return isFirstToken ? [indentation] + indentedPieces : indentedPieces
  }

  private func unindent(trivia: Trivia, by indentation: TriviaPiece) -> [TriviaPiece] {
    var indentedTrivia = [TriviaPiece]()
    for piece in trivia.pieces {
      if !isFirstToken {
        guard case .newlines = indentedTrivia.last else {
          indentedTrivia.append(piece)
          continue
        }
      }
      switch (piece, indentation) {
      case (.spaces(let number), .spaces(let requestedNumber))
      where number >= requestedNumber:
        indentedTrivia.append(.spaces(number - requestedNumber))
        if isFirstToken { break }
      case (.tabs(let number), .tabs(let requestedNumber)) where number >= requestedNumber:
        indentedTrivia.append(.tabs(number - requestedNumber))
        if isFirstToken { break }
      default: indentedTrivia.append(piece)
      }
    }
    return indentedTrivia
  }
}
