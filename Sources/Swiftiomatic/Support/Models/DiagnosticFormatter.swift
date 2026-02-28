import Foundation

/// Formats Diagnostic arrays for output.
enum DiagnosticFormatter {
    /// Encode diagnostics as pretty-printed JSON matching the CLAUDE.md spec.
    static func formatJSON(_ diagnostics: [Diagnostic]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(diagnostics)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// Format diagnostics as Xcode-compatible output (file:line:column: warning: message).
    static func formatXcode(_ diagnostics: [Diagnostic]) -> String {
        diagnostics.map { d in
            "\(d.file):\(d.line):\(d.column): \(d.severity.rawValue): [\(d.ruleID)] \(d.message)"
        }.joined(separator: "\n")
    }
}
