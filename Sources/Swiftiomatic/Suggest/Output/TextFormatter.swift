/// Formats diagnostics as human-readable text matching the swift-review scan output.
enum TextFormatter {
    static func format(_ diagnostics: [Diagnostic]) -> String {
        guard !diagnostics.isEmpty else {
            return "No findings."
        }

        var output = ""
        let grouped = Dictionary(grouping: diagnostics) { $0.category }

        // Output in section order
        for category in Category.allCases {
            guard let categoryDiags = grouped[category.rawValue], !categoryDiags.isEmpty else {
                continue
            }

            output += "## \(category.sectionNumber). \(category.displayName)\n\n"

            for diag in categoryDiags.sorted() {
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
        for category in Category.allCases {
            let count = grouped[category.rawValue]?.count ?? 0
            if count > 0 {
                output += "  §\(category.sectionNumber) \(category.displayName): \(count)\n"
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
