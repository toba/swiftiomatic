/// A single analysis finding with location, message, and metadata.
public struct Finding: Codable, Sendable, Comparable {
    public let category: Category
    public let severity: Severity
    public let file: String
    public let line: Int
    public let column: Int
    public let message: String
    public let suggestion: String?
    public let confidence: Confidence

    public init(
        category: Category,
        severity: Severity,
        file: String,
        line: Int,
        column: Int,
        message: String,
        suggestion: String? = nil,
        confidence: Confidence
    ) {
        self.category = category
        self.severity = severity
        self.file = file
        self.line = line
        self.column = column
        self.message = message
        self.suggestion = suggestion
        self.confidence = confidence
    }

    /// Sort by file path, then line, then column.
    public static func < (lhs: Finding, rhs: Finding) -> Bool {
        if lhs.file != rhs.file { return lhs.file < rhs.file }
        if lhs.line != rhs.line { return lhs.line < rhs.line }
        return lhs.column < rhs.column
    }
}
