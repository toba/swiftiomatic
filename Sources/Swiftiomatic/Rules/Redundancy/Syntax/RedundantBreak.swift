import Foundation

extension FormatRule {
  /// Remove redundant `break` keyword from switch cases
  static let redundantBreak = FormatRule(
    help: "Remove redundant `break` in switch case.",
  ) { formatter in
    formatter.forEach(.keyword("break")) { i, _ in
      guard formatter.last(.nonSpaceOrCommentOrLineBreak, before: i) != .startOfScope(":"),
        formatter.next(.nonSpaceOrCommentOrLineBreak, after: i)?.isEndOfScope == true,
        var startIndex = formatter.index(of: .nonSpace, before: i),
        let endIndex = formatter.index(of: .nonSpace, after: i),
        formatter.currentScope(at: i) == .startOfScope(":")
      else {
        return
      }
      if !formatter.tokens[startIndex].isLineBreak
        || !formatter.tokens[endIndex]
          .isLineBreak
      {
        startIndex += 1
      }
      formatter.removeTokens(in: startIndex..<endIndex)
    }
  } examples: {
    """
    ```diff
      switch foo {
        case bar:
            print("bar")
    -       break
        default:
            print("default")
    -       break
      }
    ```
    """
  }
}
