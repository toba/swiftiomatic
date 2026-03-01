import Foundation

extension FormatRule {
  /// Adds a blank line around MARK: comments
  static let blankLinesAroundMark = FormatRule(
    help: "Insert blank line before and after `MARK:` comments.",
    options: ["line-after-marks"],
    sharedOptions: ["linebreaks"],
  ) { formatter in
    formatter.forEachToken { i, token in
      guard case .commentBody(let comment) = token, comment.hasPrefix("MARK:"),
        let startIndex = formatter.index(of: .nonSpace, before: i),
        formatter.tokens[startIndex] == .startOfScope("//")
      else { return }
      if let nextIndex = formatter.index(of: .lineBreak, after: i),
        let nextToken = formatter.next(.nonSpace, after: nextIndex),
        !nextToken.isLineBreak, nextToken != .endOfScope("}"),
        formatter.options.lineAfterMarks
      {
        formatter.insertLinebreak(at: nextIndex)
      }
      if formatter.options.insertBlankLines,
        let lastIndex = formatter.index(of: .lineBreak, before: startIndex),
        let lastToken = formatter.last(.nonSpaceOrComment, before: lastIndex),
        !lastToken.isLineBreak, lastToken != .startOfScope("{")
      {
        formatter.insertLinebreak(at: lastIndex)
      }
    }
  } examples: {
    """
    ```diff
      func foo() {
        // foo
      }
      // MARK: bar
      func bar() {
        // bar
      }

      func foo() {
        // foo
      }
    +
      // MARK: bar
    +
      func bar() {
        // bar
      }
    ```
    """
  }
}
