import Foundation

extension FormatRule {
  /// Remove redundant `let error` from `catch` statements
  static let redundantLetError = FormatRule(
    help: "Remove redundant `let error` from `catch` clause.",

  ) { formatter in
    formatter.forEach(.keyword("catch")) { i, _ in
      if let letIndex = formatter.index(
        of: .nonSpaceOrCommentOrLineBreak, after: i,
        if: {
          $0 == .keyword("let")
        },
      ),
        let errorIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: letIndex,
          if: {
            $0 == .identifier("error")
          },
        ),
        let scopeIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: errorIndex,
          if: {
            $0 == .startOfScope("{")
          },
        )
      {
        formatter.removeTokens(in: letIndex..<scopeIndex)
      }
    }
  } examples: {
    """
    ```diff
    - do { ... } catch let error { log(error) }
    + do { ... } catch { log(error) }
    ```
    """
  }
}
