//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

extension Configuration {
    /// The URL of the JSON schema hosted on GitHub.
    package static let schemaURL =
        "https://raw.githubusercontent.com/toba/swiftiomatic/refs/heads/main/schema.json"

    /// Return the configuration as a JSON string with a `$schema` reference.
    ///
    /// Rule objects that fit within 100 columns are printed on a single line.
    package func asJsonString() throws(SwiftiomaticError) -> String {
        let data: Data

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            data = try encoder.encode(self)
        } catch {
            throw SwiftiomaticError.configurationDumpFailed("\(error)")
        }

        guard var jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw SwiftiomaticError.configurationDumpFailed("The JSON was not a valid object")
        }

        jsonObject["$schema"] = Self.schemaURL

        guard
            let output = try? JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            ),
            var jsonString = String(data: output, encoding: .utf8)
        else {
            throw SwiftiomaticError.configurationDumpFailed("The JSON was not valid UTF-8")
        }

        jsonString = compactSmallObjects(in: jsonString, maxWidth: 100)

        return jsonString
    }

    /// Collapses multi-line JSON objects onto a single line when they fit
    /// within `maxWidth` columns and contain only scalar values.
    private func compactSmallObjects(in json: String, maxWidth: Int) -> String {
        let lines = json.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Look for a line ending with `{` that starts a potential compact object.
            // Must be a keyed value like `"key" : {` — not a bare `{`.
            if trimmed.hasSuffix("{") && trimmed.contains("\"") {
                // Collect lines until we find the matching `}`.
                var objectLines = [line]
                var depth = 1
                var j = i + 1
                var hasNestedObject = false

                while j < lines.count && depth > 0 {
                    let inner = lines[j].trimmingCharacters(in: .whitespaces)
                    if inner.contains("{") { depth += 1; hasNestedObject = true }
                    if inner.contains("}") { depth -= 1 }
                    objectLines.append(lines[j])
                    j += 1
                }

                // Only compact if no nested objects and it fits on one line.
                if !hasNestedObject && depth == 0 {
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

    /// Joins multi-line object lines into a single-line `"key" : { ... }` form.
    private func compactObject(_ lines: [String]) -> String {
        guard let first = lines.first else { return "" }

        // Extract the indent and key portion: `  "key" : {`
        let indent = first.prefix(while: { $0 == " " })
        let keyPart = first.trimmingCharacters(in: .whitespaces)
        // Remove the trailing `{`
        let keyPrefix = String(keyPart.dropLast()).trimmingCharacters(in: .whitespaces)

        // Gather interior key-value pairs.
        var pairs: [String] = []
        for line in lines.dropFirst().dropLast() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Remove trailing comma if present.
            let clean = trimmed.hasSuffix(",") ? String(trimmed.dropLast()) : trimmed
            if !clean.isEmpty { pairs.append(clean) }
        }

        // Get the closing brace (may have trailing comma).
        let lastLine = lines.last!.trimmingCharacters(in: .whitespaces)
        let trailingComma = lastLine.hasSuffix(",") ? "," : ""

        let interior = pairs.joined(separator: ", ")
        return "\(indent)\(keyPrefix) { \(interior) }\(trailingComma)"
    }
}
