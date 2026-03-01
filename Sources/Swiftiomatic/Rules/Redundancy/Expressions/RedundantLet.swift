import Foundation

extension FormatRule {
  /// Remove redundant let/var for unnamed variables
  static let redundantLet = FormatRule(
    help: "Remove redundant `let`/`var` from ignored variables.",
  ) { formatter in
    formatter.forEach(.identifier("_")) { i, _ in
      guard formatter.next(.nonSpaceOrCommentOrLineBreak, after: i) != .delimiter(":"),
        let prevIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, before: i,
          if: {
            [.keyword("let"), .keyword("var")].contains($0)
          },
        ),
        let nextNonSpaceIndex = formatter.index(
          of: .nonSpaceOrLineBreak,
          after: prevIndex,
        )
      else {
        return
      }
      if let prevToken = formatter.last(.nonSpaceOrCommentOrLineBreak, before: prevIndex) {
        switch prevToken {
        case .keyword("if"), .keyword("guard"), .keyword("while"), .identifier("async"),
          .keyword where prevToken.isAttribute,
          .delimiter(",") where formatter.currentScope(at: i) != .startOfScope("("):
          return
        default:
          break
        }
      }
      // Crude check for Result Builder
      if formatter.isInResultBuilder(at: i) {
        return
      }
      formatter.removeTokens(in: prevIndex..<nextNonSpaceIndex)
    }
  } examples: {
    """
    ```diff
    - let _ = foo()
    + _ = foo()
    ```
    """
  }
}
