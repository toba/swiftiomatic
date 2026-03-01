import SwiftSyntax

extension SwiftSource {
  /// Counts effective body lines between braces, ignoring comment-only and blank lines
  ///
  /// - Parameters:
  ///   - leftBraceLine: The line number of the opening brace.
  ///   - rightBraceLine: The line number of the closing brace.
  func bodyLineCountIgnoringCommentsAndWhitespace(
    leftBraceLine: Int, rightBraceLine: Int,
  ) -> Int {
    // Ignore left/right brace lines
    let startLine = min(leftBraceLine + 1, rightBraceLine - 1)
    let endLine = max(rightBraceLine - 1, leftBraceLine + 1)
    // Add one because if `endLine == startLine` it's still a one-line "body". Here are some examples:
    //
    //   # 1 line
    //   {}
    //
    //   # 1 line
    //   {
    //   }
    //
    //   # 1 line
    //   {
    //     print("foo")
    //   }
    //
    //   # 2 lines
    //   {
    //     let sum = 1 + 2
    //     print(sum)
    //   }
    let totalNumberOfLines = 1 + endLine - startLine
    let numberOfCommentAndWhitespaceOnlyLines = Set(startLine...endLine).subtracting(
      linesWithTokens,
    ).count
    return totalNumberOfLines - numberOfCommentAndWhitespaceOnlyLines
  }

  /// Builds the set of line numbers that contain at least one meaningful token
  func computeLinesWithTokens() -> Set<Int> {
    let locationConverter = locationConverter
    return
      syntaxTree
      .tokens(viewMode: .sourceAccurate)
      .reduce(into: []) { linesWithTokens, token in
        if case .stringSegment = token.tokenKind {
          let sourceRange = token.sourceRange(
            converter: locationConverter,
            afterLeadingTrivia: true,
            afterTrailingTrivia: true,
          )
          linesWithTokens.formUnion(sourceRange.start.line...sourceRange.end.line)
        } else {
          let line =
            locationConverter
            .location(for: token.positionAfterSkippingLeadingTrivia).line
          linesWithTokens.insert(line)
        }
      }
  }
}
