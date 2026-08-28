import Foundation

/// Collapses a multi-line JSON object onto one line when it holds only scalar values and fits
/// within a column budget.
///
/// Both the `dump-configuration` output and the entries `sm update` inserts use this, so a rule
/// object reads the same way whichever path wrote it.
enum JSONCompaction {
    /// Rewrites `json` , compacting each qualifying object.
    ///
    /// - Parameters:
    ///   - json: Serialized JSON, one token per line.
    ///   - maxWidth: The column budget a compacted object must fit inside.
    ///   - requiringQuotedKey: Compact an object only when its opening line carries a quoted key,
    ///     as in `"rule": {` . Pass `false` when compacting a value that was serialized on its own,
    ///     where the opening line is a bare `{` .
    static func compactSmallObjects(
        in json: String,
        maxWidth: Int,
        requiringQuotedKey: Bool
    ) -> String {
        let lines = json.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let opensObject = trimmed.hasSuffix("{")
                && (!requiringQuotedKey || trimmed.contains("\""))

            if opensObject {
                // Collect lines through the matching `}` .
                var objectLines = [line]
                var depth = 1
                var j = i + 1
                var hasNestedObject = false

                while j < lines.count, depth > 0 {
                    let inner = lines[j].trimmingCharacters(in: .whitespaces)

                    if inner.contains("{") {
                        depth += 1
                        hasNestedObject = true
                    }
                    if inner.contains("}") { depth -= 1 }
                    objectLines.append(lines[j])
                    j += 1
                }

                // Compact only a closed object that nests nothing and fits on one line.
                if !hasNestedObject, depth == 0 {
                    let compact = compactObject(objectLines)

                    if compact.count <= maxWidth {
                        result.append(compact)
                        i = j
                        continue
                    }
                }
            }
            result.append(line)
            i += 1
        }
        return result.joined(separator: "\n")
    }

    /// Joins the lines of one object into a single-line `"key": { … }` form.
    private static func compactObject(_ lines: [String]) -> String {
        guard let first = lines.first, let last = lines.last else { return "" }

        // Extract the indent and the key portion of `  "key": {` .
        let indent = first.prefix(while: { $0 == " " })
        let keyPrefix = String(first.trimmingCharacters(in: .whitespaces).dropLast())
            .trimmingCharacters(in: .whitespaces)
        var pairs: [String] = []

        for line in lines.dropFirst().dropLast() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let clean = trimmed.hasSuffix(",") ? String(trimmed.dropLast()) : trimmed
            if !clean.isEmpty { pairs.append(clean) }
        }
        let trailingComma = last.trimmingCharacters(in: .whitespaces).hasSuffix(",") ? "," : ""
        // A value compacted on its own carries no `"key":` , so emitting the separator would put a
        // second space after the colon that precedes it.
        let separator = keyPrefix.isEmpty ? "" : " "

        return
            "\(indent)\(keyPrefix)\(separator){ \(pairs.joined(separator: ", ")) }\(trailingComma)"
    }
}
