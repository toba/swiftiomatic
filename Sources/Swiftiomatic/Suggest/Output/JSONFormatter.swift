import Foundation

/// Formats findings as JSON for agent consumption.
enum JSONFormatter {
    static func format(_ findings: [Finding]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(findings)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}
