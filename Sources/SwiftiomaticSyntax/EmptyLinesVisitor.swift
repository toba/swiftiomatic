package import SwiftSyntax

/// Finds source lines that are completely empty (no code, no comments)
package final class EmptyLinesVisitor: SyntaxVisitor {
  private let locationConverter: SourceLocationConverter

  private var linesWithContent = Set<Int>()
  private var lastLine = 0

  /// Line numbers that contain neither code nor comments
  package var emptyLines: Set<Int> {
    guard lastLine > 0 else { return [] }
    let allLines = Set(1...lastLine)
    return allLines.subtracting(linesWithContent)
  }

  /// Creates a visitor with the given location converter
  ///
  /// - Parameters:
  ///   - locationConverter: The converter for mapping positions to line numbers.
  package init(locationConverter: SourceLocationConverter) {
    self.locationConverter = locationConverter
    super.init(viewMode: .sourceAccurate)
  }

  /// Computes empty lines in the given source file
  ///
  /// - Parameters:
  ///   - file: The source file to analyze.
  /// - Returns: A set of line numbers that are empty.
  package static func emptyLines(in file: SwiftSource) -> Set<Int> {
    EmptyLinesVisitor(locationConverter: file.locationConverter)
      .walk(tree: file.syntaxTree, handler: \.emptyLines)
  }

  package override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
    applyTriviaResult(
      TriviaLineCollector.collectLines(
        from: token.leadingTrivia,
        endingAt: token.positionAfterSkippingLeadingTrivia,
        using: locationConverter,
      ),
    )

    // Mark lines with actual code tokens (not comments).
    if token.tokenKind != .endOfFile {
      let tokenLine =
        locationConverter
        .location(for: token.positionAfterSkippingLeadingTrivia).line
      linesWithContent.insert(tokenLine)
      lastLine = max(lastLine, tokenLine)
    } else {
      // For EOF token, we only update lastLine based on its position if there's actual content
      // EOF on line 1 with no preceding content means the file is empty.
      let eofLine = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia)
        .line
      if eofLine > 1 || !linesWithContent.isEmpty {
        lastLine = max(lastLine, eofLine - 1)  // Don't count the EOF line itself.
      }
    }

    applyTriviaResult(
      TriviaLineCollector.collectLines(
        from: token.trailingTrivia,
        endingAt: token.endPosition,
        using: locationConverter,
      ),
    )

    return .visitChildren
  }

  private func applyTriviaResult(_ result: TriviaLineCollector.Result) {
    linesWithContent.formUnion(result.commentLines)
    if let maxCommentLine = result.commentLines.max() {
      lastLine = max(lastLine, maxCommentLine)
    }
    if let maxNewlineLine = result.maxNewlineLine {
      lastLine = max(lastLine, maxNewlineLine)
    }
  }
}
