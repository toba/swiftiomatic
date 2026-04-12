import SwiftiomaticSyntax

/// Maps lint rules that are superseded by format rules to avoid duplicate diagnostics
///
/// When format-lint is active, lint rules in this map are skipped because the format
/// engine already covers the same check (often with auto-fix capability).
public enum DiagnosticDeduplicator {
  /// Lint rule ID to format rule name that supersedes it
  static let lintSupersededByFormat: [String: String] = [
    "trailing_whitespace": "trailingSpace",
    "trailing_newline": "linebreakAtEndOfFile",
    "leading_whitespace": "leadingDelimiters",
    "vertical_whitespace": "consecutiveBlankLines",
    "comma": "spaceAroundOperators",
    "sort_imports": "sortImports",
    "duplicate_imports": "duplicateImports",
    "opening_brace": "braces",
    "statement_position": "elseOnSameLine",
    "return_arrow_spacing": "spaceAroundOperators",
    "colon": "spaceAroundOperators",
    "mark": "blankLinesAroundMark",
  ]

  /// Remove lint diagnostics that overlap with active format diagnostics
  ///
  /// - Parameters:
  ///   - diagnostics: The full set of diagnostics from both lint and format passes.
  /// - Returns: The filtered diagnostics with superseded lint entries removed.
  public static func deduplicate(_ diagnostics: [Diagnostic]) -> [Diagnostic] {
    let activeFormatRules = Set(diagnostics.filter { $0.source == .format }.map(\.ruleID))
    guard !activeFormatRules.isEmpty else { return diagnostics }

    return diagnostics.filter { d in
      if d.source == .lint,
        let formatEquivalent = lintSupersededByFormat[d.ruleID],
        activeFormatRules.contains(formatEquivalent)
      {
        return false
      }
      return true
    }
  }
}
