import Foundation

/// Unified output type that all three analysis engines produce at the reporting boundary.
/// Maps directly to the swift-review skill's output format and the JSON spec from CLAUDE.md.
public struct Diagnostic: Codable, Sendable, Comparable {
    /// The identifier of the rule that produced this diagnostic.
    public let ruleID: String

    /// Which engine produced this diagnostic.
    public let source: DiagnosticSource

    /// Warning or error.
    public let severity: DiagnosticSeverity

    /// Confidence in the finding.
    public let confidence: Confidence

    /// Source file path.
    public let file: String

    /// 1-indexed line number.
    public let line: Int

    /// 1-indexed column number.
    public let column: Int

    /// Human-readable description of the issue.
    public let message: String

    /// Suggested fix, if available.
    public let suggestion: String?

    /// Whether this diagnostic can be auto-fixed by the engine that produced it.
    public let canAutoFix: Bool

    public static func < (lhs: Diagnostic, rhs: Diagnostic) -> Bool {
        if lhs.file != rhs.file { return lhs.file < rhs.file }
        if lhs.line != rhs.line { return lhs.line < rhs.line }
        return lhs.column < rhs.column
    }
}

/// Which analysis engine produced a diagnostic.
public enum DiagnosticSource: String, CaseIterable, Codable, Sendable {
    case suggest
    case lint
    case format

    /// Human-readable display name for text output.
    public var displayName: String {
        switch self {
            case .suggest: "Suggestions"
            case .lint: "Lint"
            case .format: "Format"
        }
    }
}

/// Diagnostic severity — warning or error.
public enum DiagnosticSeverity: String, Codable, Sendable, CaseIterable, Comparable {
    case warning
    case error
}
