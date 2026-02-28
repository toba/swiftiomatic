/// A single analysis finding with location, message, and metadata.
struct Finding: Codable, Sendable, Comparable {
    let category: Category
    let severity: Severity
    let file: String
    let line: Int
    let column: Int
    let message: String
    let suggestion: String?
    let confidence: Confidence

    init(
        category: Category,
        severity: Severity,
        file: String,
        line: Int,
        column: Int,
        message: String,
        suggestion: String? = nil,
        confidence: Confidence,
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
    static func < (lhs: Finding, rhs: Finding) -> Bool {
        if lhs.file != rhs.file { return lhs.file < rhs.file }
        if lhs.line != rhs.line { return lhs.line < rhs.line }
        return lhs.column < rhs.column
    }

    /// Convert to the unified Diagnostic output type.
    func toDiagnostic() -> Diagnostic {
        Diagnostic(
            ruleID: category.rawValue,
            engine: .suggest,
            category: category.rawValue,
            severity: severity == .high ? .error : .warning,
            confidence: confidence,
            file: file,
            line: line,
            column: column,
            message: message,
            suggestion: suggestion,
            canAutoFix: false,
        )
    }
}
