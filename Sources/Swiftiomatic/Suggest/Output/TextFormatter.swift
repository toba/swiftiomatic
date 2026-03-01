/// Formats diagnostics as human-readable text grouped by source.
package enum TextFormatter {
    package static func format(_ diagnostics: [Diagnostic]) -> String {
        guard !diagnostics.isEmpty else {
            return "No findings."
        }

        var output = ""
        let grouped = Dictionary(grouping: diagnostics) { $0.source }

        // Output in Source case order
        for (sectionNumber, source) in Source.allCases.enumerated() {
            guard let sourceDiags = grouped[source], !sourceDiags.isEmpty else {
                continue
            }

            output += "## \(sectionNumber + 1). \(source.displayName)\n\n"

            for diag in sourceDiags.sorted() {
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
        for (sectionNumber, source) in Source.allCases.enumerated() {
            let count = grouped[source]?.count ?? 0
            if count > 0 {
                output += "  §\(sectionNumber + 1) \(source.displayName): \(count)\n"
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
