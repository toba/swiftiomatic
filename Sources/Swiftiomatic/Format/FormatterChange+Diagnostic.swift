extension Formatter.Change {
    /// Converts this change record into a unified ``Diagnostic`` for reporting
    public func toDiagnostic() -> Diagnostic {
        Diagnostic(
            ruleID: rule.name,
            source: .format,
            severity: .warning,
            confidence: .high,
            file: filePath ?? "<unknown>",
            line: line,
            column: 1,
            message: help,
            suggestion: nil,
            canAutoFix: true,
        )
    }
}
