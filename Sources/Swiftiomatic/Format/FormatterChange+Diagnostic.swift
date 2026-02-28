extension Formatter.Change {
    /// Convert to the unified Diagnostic output type.
    func toDiagnostic() -> Diagnostic {
        Diagnostic(
            ruleID: rule.name,
            engine: .format,
            category: "format",
            severity: .warning,
            confidence: .high,
            file: filePath ?? "<unknown>",
            line: line,
            column: 1,
            message: help,
            suggestion: nil,
            canAutoFix: true
        )
    }
}
