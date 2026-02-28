/// Formats diagnostics as human-readable text grouped by rule kind.
enum TextFormatter {
    static func format(_ diagnostics: [Diagnostic]) -> String {
        guard !diagnostics.isEmpty else {
            return "No findings."
        }

        var output = ""
        let grouped = Dictionary(grouping: diagnostics) { $0.category }

        // Output in RuleKind case order
        for (sectionNumber, kind) in RuleKind.allCases.enumerated() {
            guard let kindDiags = grouped[kind.rawValue], !kindDiags.isEmpty else {
                continue
            }

            output += "## \(sectionNumber + 1). \(kind.displayName)\n\n"

            for diag in kindDiags.sorted() {
                let confidence = confidenceMarker(diag.confidence)
                output += "\(confidence) \(diag.file):\(diag.line):\(diag.column): "
                output += "[\(diag.severity.rawValue)] \(diag.message)\n"
                if let suggestion = diag.suggestion {
                    output += "  → \(suggestion)\n"
                }
            }

            output += "\n"
        }

        // Summary
        output += "## Summary\n\n"
        for (sectionNumber, kind) in RuleKind.allCases.enumerated() {
            let count = grouped[kind.rawValue]?.count ?? 0
            if count > 0 {
                output += "  §\(sectionNumber + 1) \(kind.displayName): \(count)\n"
            }
        }
        output += "  Total: \(diagnostics.count)\n"

        return output
    }

    private static func confidenceMarker(_ confidence: Confidence) -> String {
        switch confidence {
            case .high: "●"
            case .medium: "◐"
            case .low: "○"
        }
    }
}
