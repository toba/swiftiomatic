import Foundation

/// Formats ``Diagnostic`` arrays for CLI and Xcode output
public enum DiagnosticFormatter {
  /// Encodes diagnostics as pretty-printed JSON matching the output spec
  ///
  /// - Parameters:
  ///   - diagnostics: The diagnostics to encode.
  /// - Returns: A JSON string with sorted keys.
  /// - Throws: Rethrows encoding errors from `JSONEncoder`.
  public static func formatJSON(_ diagnostics: [Diagnostic]) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(diagnostics)
    return String(data: data, encoding: .utf8) ?? "[]"
  }

  /// Formats diagnostics as Xcode-compatible output (`file:line:column: warning: message`)
  ///
  /// - Parameters:
  ///   - diagnostics: The diagnostics to format.
  /// - Returns: A newline-separated string of Xcode-style diagnostic lines.
  public static func formatXcode(_ diagnostics: [Diagnostic]) -> String {
    diagnostics.map { d in
      "\(d.file):\(d.line):\(d.column): \(d.severity.rawValue): [\(d.ruleID)] \(d.message)"
    }.joined(separator: "\n")
  }
}
