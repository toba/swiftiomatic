import Foundation

extension FormatRule {
  /// Convert force-unwrapped URL initializers to use the #URL(...) macro
  static let urlMacro = FormatRule(
    help:
      "Replace force-unwrapped `URL(string:)` initializers with the configured `#URL(_:)` macro.",
    disabledByDefault: true,
    options: ["url-macro"],
  ) { formatter in
    // Only apply this rule if a URL macro is configured
    guard case .macro(let macroName, module: let module) = formatter.options.urlMacro else {
      return
    }
    // First collect all indices to process
    var indicesToProcess: [(Int, Int, Int, Int)] =
      []  // (i, firstArgIndex, stringStartIndex, unwrapIndex)

    formatter.forEach(.identifier("URL")) { i, _ in
      // Look for `URL(string: "...")!` pattern
      guard let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLineBreak, after: i),
        formatter.tokens[openParenIndex] == .startOfScope("("),
        let firstArgIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: openParenIndex,
        ),
        formatter.tokens[firstArgIndex] == .identifier("string"),
        let colonIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak,
          after: firstArgIndex,
        ),
        formatter.tokens[colonIndex] == .delimiter(":"),
        let stringStartIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: colonIndex,
        ),
        formatter.tokens[stringStartIndex] == .startOfScope("\""),
        let stringEndIndex = formatter.index(
          of: .endOfScope("\""),
          after: stringStartIndex,
        ),
        let closeParenIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: stringEndIndex,
        ),
        formatter.tokens[closeParenIndex] == .endOfScope(")"),
        let unwrapIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, after: closeParenIndex,
        ),
        formatter.tokens[unwrapIndex] == .operator("!", .postfix)
      else { return }

      // Only convert simple string literals (no interpolation, concatenation, etc.)
      // Check if there are any tokens between the string delimiters that indicate non-literal content
      var hasNonLiteralContent = false
      for tokenIndex in (stringStartIndex + 1)..<stringEndIndex {
        let token = formatter.tokens[tokenIndex]
        switch token {
        case .stringBody:
          // String body is fine - this is the literal content
          continue
        case .startOfScope("\\("), .endOfScope(")"):
          // String interpolation detected
          hasNonLiteralContent = true
        default:
          // Any other tokens between string delimiters suggest complex content
          hasNonLiteralContent = true
        }
      }

      // Skip if this is not a simple string literal
      guard !hasNonLiteralContent else { return }

      indicesToProcess.append((i, firstArgIndex, stringStartIndex, unwrapIndex))
    }

    // Process changes in reverse order to avoid index shifts
    for (i, firstArgIndex, stringStartIndex, unwrapIndex) in indicesToProcess.reversed() {
      // Remove the unwrap operator first (working backwards to avoid index shifts)
      formatter.removeToken(at: unwrapIndex)

      // Remove "string: " argument
      formatter.removeTokens(in: firstArgIndex..<stringStartIndex)

      // Replace "URL" with the configured macro name
      formatter.replaceToken(at: i, with: .keyword(macroName))
    }

    // Add the configured module import if any modifications were made
    if !indicesToProcess.isEmpty {
      formatter.addImports([module])
    }
  } examples: {
    """
    With `--url-macro "#URL,URLFoundation"`:

    ```diff
    - let url = URL(string: "https://example.com")!
    + import URLFoundation
    + let url = #URL("https://example.com")
    ```

    ```diff
    - return URL(string: "https://api.example.com/users")!
    + import URLFoundation
    + return #URL("https://api.example.com/users")
    ```
    """
  }
}
