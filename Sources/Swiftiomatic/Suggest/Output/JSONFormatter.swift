import Foundation

/// Formats diagnostics as JSON for agent consumption.
///
/// Delegates to DiagnosticFormatter, which encodes the unified Diagnostic type.
enum JSONFormatter {
    static func format(_ diagnostics: [Diagnostic]) throws -> String {
        try DiagnosticFormatter.formatJSON(diagnostics)
    }
}
