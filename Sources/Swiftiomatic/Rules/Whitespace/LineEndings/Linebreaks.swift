import Foundation

extension FormatRule {
  /// Standardise linebreak characters as whatever is specified in the options (\n by default)
  static let linebreaks = FormatRule(
    help: "Use specified linebreak character for all linebreaks (CR, LF or CRLF).",
    options: ["linebreaks"],
  ) { formatter in
    formatter.forEach(.lineBreak) { i, _ in
      formatter.replaceToken(at: i, with: formatter.linebreakToken(for: i))
    }
  } examples: {
    nil
  }
}
