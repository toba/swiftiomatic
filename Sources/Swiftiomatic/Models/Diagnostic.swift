import Foundation

/// Unified output type that all three analysis engines produce at the reporting boundary.
/// Maps directly to the swift-review skill's output format and the JSON spec from CLAUDE.md.
package struct Diagnostic: Codable, Sendable, Comparable {
    /// The identifier of the rule that produced this diagnostic.
    package let ruleID: String

    /// Which engine produced this diagnostic.
    package let source: Source

    /// Warning or error.
    package let severity: DiagnosticSeverity

    /// Confidence in the finding.
    package let confidence: Confidence

    /// Source file path.
    package let file: String

    /// 1-indexed line number.
    package let line: Int

    /// 1-indexed column number.
    package let column: Int

    /// Human-readable description of the issue.
    package let message: String

    /// Suggested fix, if available.
    package let suggestion: String?

    /// Whether this diagnostic can be auto-fixed by the engine that produced it.
    package let canAutoFix: Bool

    package static func < (lhs: Diagnostic, rhs: Diagnostic) -> Bool {
        if lhs.file != rhs.file { return lhs.file < rhs.file }
        if lhs.line != rhs.line { return lhs.line < rhs.line }
        return lhs.column < rhs.column
    }
}

/// Which analysis engine produced a diagnostic.
package enum Source: String, CaseIterable, Codable, Sendable {
    case suggest
    case lint
    case format

    /// Human-readable display name for text output.
    var displayName: String {
        switch self {
            case .suggest: "Suggestions"
            case .lint: "Lint"
            case .format: "Format"
        }
    }
}

/// Diagnostic severity — warning or error.
package enum DiagnosticSeverity: String, Codable, Sendable, CaseIterable, Comparable {
    case warning
    case error

    package static func < (lhs: DiagnosticSeverity, rhs: DiagnosticSeverity) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}
