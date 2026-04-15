import SwiftSyntax

/// Enforce a consistent file header comment, or remove file headers entirely.
///
/// When configured with header text, any existing file header comment is replaced with the
/// configured text. When configured with an empty string, any existing file header is removed.
/// File header comments are line comments (`//`) or block comments (`/* */`) at the start of
/// the file, before any blank line, doc comment, or code. Doc comments (`///`, `/** */`) are
/// not considered file header comments.
///
/// This rule is opt-in and requires configuration via `fileHeader.text` in the configuration file.
///
/// Lint: A warning is raised when the file header does not match the configured text.
///
/// Format: The file header is replaced with (or cleared to) the configured text.
@_spi(Rules)
public final class FileHeader: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    guard let text = context.configuration.fileHeader.text else { return node }

    if node.statements.isEmpty {
      // File has no code — header is on the EOF token
      let trivia = node.endOfFileToken.leadingTrivia
      guard let newTrivia = processHeader(trivia: trivia, text: text, hasCodeAfter: false)
      else { return node }
      diagnose(.updateFileHeader, on: node.endOfFileToken)
      var result = node
      result.endOfFileToken = node.endOfFileToken.with(\.leadingTrivia, newTrivia)
      return result
    }

    let firstStmt = node.statements.first!
    let trivia = firstStmt.leadingTrivia
    guard let newTrivia = processHeader(trivia: trivia, text: text, hasCodeAfter: true)
    else { return node }
    diagnose(.updateFileHeader, on: firstStmt)
    var statements = Array(node.statements)
    statements[0] = firstStmt.with(\.leadingTrivia, newTrivia)
    var result = node
    result.statements = CodeBlockItemListSyntax(statements)
    return result
  }

  // MARK: - Header processing

  /// Returns the new trivia if it differs from the current trivia, or `nil` if no change is needed.
  private func processHeader(trivia: Trivia, text: String, hasCodeAfter: Bool) -> Trivia? {
    let pieces = Array(trivia.pieces)
    let headerEnd = findHeaderEnd(in: pieces)
    let rest = Array(pieces[headerEnd...])

    var newPieces: [TriviaPiece]

    if text.isEmpty {
      // Clear mode: if no header exists, nothing to do
      if headerEnd == 0 { return nil }
      newPieces = trimLeadingWhitespace(rest)
    } else {
      // Replace mode: new header + blank line + rest
      let headerPieces = parseHeaderText(text)
      let trimmedRest = trimLeadingWhitespace(rest)
      newPieces = headerPieces
      if !trimmedRest.isEmpty || hasCodeAfter {
        newPieces.append(.newlines(2))
        newPieces.append(contentsOf: trimmedRest)
      } else {
        // No code after header (EOF-only file): preserve original trailing trivia
        newPieces.append(contentsOf: rest)
      }
    }

    let newTrivia = Trivia(pieces: newPieces)
    return newTrivia == trivia ? nil : newTrivia
  }

  // MARK: - Header boundary detection

  /// Returns the index in `pieces` where the file header ends.
  ///
  /// The header consists of consecutive `.lineComment`, `.blockComment`, and `.docBlockComment`
  /// pieces at the start of the trivia, connected by single newlines and whitespace.
  /// `.docLineComment` (`///`) is NOT part of the header — it typically precedes declarations.
  /// `.docBlockComment` (`/** */`, `/*** ***/`) IS included because swift-syntax classifies
  /// decorative block comment borders like `/***...***/` as doc block comments.
  private func findHeaderEnd(in pieces: [TriviaPiece]) -> Int {
    var lastCommentEnd = 0
    var i = 0

    while i < pieces.count {
      switch pieces[i] {
      case .lineComment, .blockComment, .docBlockComment:
        lastCommentEnd = i + 1
        i += 1
      case .spaces, .tabs:
        i += 1
      case .newlines(1), .carriageReturns(1), .carriageReturnLineFeeds(1):
        i += 1
      default:
        // Blank line (newlines >= 2), doc comment, or other content
        return lastCommentEnd
      }
    }

    return lastCommentEnd
  }

  // MARK: - Text parsing

  /// Converts a header text string into trivia pieces.
  ///
  /// Each line becomes a `.lineComment` piece (or `.blockComment` if it starts with `/*`),
  /// separated by `.newlines(1)`.
  private func parseHeaderText(_ text: String) -> [TriviaPiece] {
    guard !text.isEmpty else { return [] }

    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    var pieces: [TriviaPiece] = []
    for (i, line) in lines.enumerated() {
      let lineStr = String(line)
      if lineStr.hasPrefix("/*") {
        pieces.append(.blockComment(lineStr))
      } else {
        pieces.append(.lineComment(lineStr))
      }
      if i < lines.count - 1 {
        pieces.append(.newlines(1))
      }
    }
    return pieces
  }

  // MARK: - Trivia helpers

  /// Removes leading whitespace-only trivia pieces (newlines, spaces, tabs).
  private func trimLeadingWhitespace(_ pieces: [TriviaPiece]) -> [TriviaPiece] {
    var result = pieces
    while let first = result.first {
      switch first {
      case .newlines, .spaces, .tabs, .carriageReturns, .carriageReturnLineFeeds, .formfeeds:
        result.removeFirst()
      default:
        return result
      }
    }
    return result
  }
}

extension Finding.Message {
  fileprivate static let updateFileHeader: Finding.Message =
    "update file header to match configured text"
}
