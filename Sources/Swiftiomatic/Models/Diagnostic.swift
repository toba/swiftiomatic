import Foundation

/// Unified output type that all three analysis engines produce at the reporting boundary.
/// Maps directly to the swift-review skill's output format and the JSON spec from CLAUDE.md.
struct Diagnostic: Codable, Sendable, Comparable {
    /// The identifier of the rule that produced this diagnostic.
    let ruleID: String

    /// Which engine produced this diagnostic.
    let source: Source

    /// Warning or error.
    let severity: DiagnosticSeverity

    /// Confidence in the finding.
    let confidence: Confidence

    /// Source file path.
    let file: String

    /// 1-indexed line number.
    let line: Int

    /// 1-indexed column number.
    let column: Int

    /// Human-readable description of the issue.
    let message: String

    /// Suggested fix, if available.
    let suggestion: String?

    /// Whether this diagnostic can be auto-fixed by the engine that produced it.
    let canAutoFix: Bool

    static func < (lhs: Diagnostic, rhs: Diagnostic) -> Bool {
        if lhs.file != rhs.file { return lhs.file < rhs.file }
        if lhs.line != rhs.line { return lhs.line < rhs.line }
        return lhs.column < rhs.column
    }
}

/// Which analysis engine produced a diagnostic.
enum Source: String, CaseIterable, Codable, Sendable {
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
enum DiagnosticSeverity: String, Codable, Sendable, Comparable {
    case warning
    case error

    private var rank: Int {
        switch self {
            case .warning: 0
            case .error: 1
        }
    }

    static func < (lhs: DiagnosticSeverity, rhs: DiagnosticSeverity) -> Bool {
        lhs.rank < rhs.rank
    }
}
