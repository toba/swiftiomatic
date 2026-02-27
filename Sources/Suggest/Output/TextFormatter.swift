/// Formats findings as human-readable text matching the swift-review scan output.
public enum TextFormatter {
    public static func format(_ findings: [Finding]) -> String {
        guard !findings.isEmpty else {
            return "No findings."
        }

        var output = ""
        let grouped = Dictionary(grouping: findings) { $0.category }

        // Output in section order
        for category in Category.allCases {
            guard let categoryFindings = grouped[category], !categoryFindings.isEmpty else {
                continue
            }

            output += "## \(category.sectionNumber). \(category.displayName)\n\n"

            for finding in categoryFindings.sorted() {
                let confidence = confidenceMarker(finding.confidence)
                output += "\(confidence) \(finding.file):\(finding.line):\(finding.column): "
                output += "[\(finding.severity)] \(finding.message)\n"
                if let suggestion = finding.suggestion {
                    output += "  → \(suggestion)\n"
                }
            }

            output += "\n"
        }

        // Summary
        output += "## Summary\n\n"
        for category in Category.allCases {
            let count = grouped[category]?.count ?? 0
            if count > 0 {
                output += "  §\(category.sectionNumber) \(category.displayName): \(count)\n"
            }
        }
        output += "  Total: \(findings.count)\n"

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
