import Foundation

extension FormatRule {
    /// Ensure there is no space between an opening chevron and the preceding identifier
    static let spaceAroundGenerics = FormatRule(
        help: "Remove space around angle brackets.",
    ) { formatter in
        formatter.forEach(.startOfScope("<")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
               formatter.token(at: i - 2)?.isIdentifierOrKeyword == true
            {
                formatter.removeToken(at: i - 1)
            }
        }
    } examples: {
        """
        ```diff
        - Foo <Bar> ()
        + Foo<Bar>()
        ```
        """
    }
}
