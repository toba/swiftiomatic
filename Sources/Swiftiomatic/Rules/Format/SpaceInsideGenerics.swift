import Foundation

extension FormatRule {
    /// Remove space immediately inside chevrons
    static let spaceInsideGenerics = FormatRule(
        help: "Remove space inside angle brackets.",
    ) { formatter in
        formatter.forEach(.startOfScope("<")) { i, _ in
            if formatter.token(at: i + 1)?.isSpace == true {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope(">")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
               formatter.token(at: i - 2)?.isLinebreak == false
            {
                formatter.removeToken(at: i - 1)
            }
        }
    } examples: {
        """
        ```diff
        - Foo< Bar, Baz >
        + Foo<Bar, Baz>
        ```
        """
    }
}
