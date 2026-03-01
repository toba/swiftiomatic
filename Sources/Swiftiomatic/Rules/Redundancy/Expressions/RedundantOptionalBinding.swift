import Foundation

extension FormatRule {
  static let redundantOptionalBinding = FormatRule(
    help: "Remove redundant identifiers in optional binding conditions.",
  ) { formatter in
    formatter.forEachToken { i, token in
      // `if let foo` conditions were added in Swift 5.7 (SE-0345)
      if formatter.options.swiftVersion >= "5.7",

        [.keyword("let"), .keyword("var")].contains(token),
        formatter.isConditionalStatement(at: i),

        let identiferIndex = formatter.index(of: .nonSpaceOrCommentOrLineBreak, after: i),
        let identifier = formatter.token(at: identiferIndex),

        let equalsIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: identiferIndex,
          if: {
            $0 == .operator("=", .infix)
          },
        ),

        let nextIdentifierIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: equalsIndex,
          if: {
            $0 == identifier
          },
        ),

        let nextToken = formatter.next(
          .nonSpaceOrCommentOrLineBreak,
          after: nextIdentifierIndex,
        ),
        [.startOfScope("{"), .delimiter(","), .keyword("else")].contains(nextToken)
      {
        formatter.removeTokens(in: identiferIndex + 1...nextIdentifierIndex)
      }
    }
  } examples: {
    """
    ```diff
    - if let foo = foo {
    + if let foo {
          print(foo)
      }

    - guard let self = self else {
    + guard let self else {
          return
      }
    ```
    """
  }
}
