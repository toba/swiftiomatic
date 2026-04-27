import Foundation

/// Controls the order of keys in serialized JSON output.
package enum KeySortOrder: String, Sendable, CaseIterable {
    /// Sort by key length ascending, alphabetical tiebreaker.
    case length
    /// Sort alphabetically (lexicographic).
    case alphabetical
}

/// A JSON value suitable for schema validation, configuration encoding, and any context that needs
/// a fully typed JSON representation without ObjC bridging ( `[String: Any]` ).
///
/// `JSONDecoder` with `allowsJSON5` produces these directly.
package enum JSONValue: Sendable, Equatable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null
}

extension JSONValue: Codable {
    package init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([JSONValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: JSONValue].self) {
            self = .object(v)
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported JSON value"
                ))
        }
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case let .string(v): try container.encode(v)
            case let .int(v): try container.encode(v)
            case let .double(v): try container.encode(v)
            case let .bool(v): try container.encode(v)
            case let .array(v): try container.encode(v)
            case let .object(v): try container.encode(v)
            case .null: try container.encodeNil()
        }
    }
}

package extension JSONValue {
    /// Human-readable description for error messages.
    var displayDescription: String {
        switch self {
            case let .string(s): s
            case let .int(n): "\(n)"
            case let .double(n): "\(n)"
            case let .bool(b): b ? "true" : "false"
            case .object: "{...}"
            case .array: "[...]"
            case .null: "null"
        }
    }

    /// The JSON Schema type name for this value.
    var schemaTypeName: String {
        switch self {
            case .string: "string"
            case .int: "integer"
            case .double: "number"
            case .bool: "boolean"
            case .object: "object"
            case .array: "array"
            case .null: "null"
        }
    }

    /// Whether this value matches the given JSON Schema type name.
    func matches(schemaType type: String) -> Bool {
        switch type {
            case "string": if case .string = self { return true }
            case "integer": if case .int = self { return true }
            case "number":
                switch self {
                    case .int, .double: return true
                    default: break
                }
            case "boolean": if case .bool = self { return true }
            case "object": if case .object = self { return true }
            case "array": if case .array = self { return true }
            case "null": if case .null = self { return true }
            default: break
        }
        return false
    }

    /// Numeric value for comparisons, if applicable.
    var numericValue: Double? {
        switch self {
            case let .int(n): Double(n)
            case let .double(n): n
            default: nil
        }
    }
}

// MARK: - Serialization

extension JSONValue {
    /// Serialize to a pretty-printed JSON string with keys ordered by `sortBy` .
    public func serialize(sortBy order: KeySortOrder = .length) -> String {
        var output = ""
        write(to: &output, indent: 0, sortBy: order)
        return output
    }

    private func write(to output: inout String, indent: Int, sortBy order: KeySortOrder) {
        switch self {
            case let .string(s):
                output += "\""
                output += escapeJSON(s)
                output += "\""
            case let .int(n): output += "\(n)"
            case let .double(n): output += "\(n)"
            case let .bool(b): output += b ? "true" : "false"
            case .null: output += "null"
            case let .array(elements):
                if elements.isEmpty {
                    output += "[]"
                    return
                }
                output += "[\n"
                let childIndent = indent + 2
                for (i, element) in elements.enumerated() {
                    output += String(repeating: " ", count: childIndent)
                    element.write(to: &output, indent: childIndent, sortBy: order)
                    if i < elements.count - 1 { output += "," }
                    output += "\n"
                }
                output += String(repeating: " ", count: indent)
                output += "]"
            case let .object(dict):
                if dict.isEmpty {
                    output += "{}"
                    return
                }
                let sortedKeys: [String]
                // Pin $schema and version to the top of the root object only.
                if indent == 0 {
                    let pinned = ["$schema", "version"]
                    let pinnedSet = Set(pinned)
                    let pinnedPresent = pinned.filter { dict.keys.contains($0) }
                    let remaining = dict.keys.filter { !pinnedSet.contains($0) }
                    switch order {
                        case .length:
                            sortedKeys = pinnedPresent
                                + remaining.sorted {
                                    $0.count < $1.count || ($0.count == $1.count && $0 < $1)
                                }
                        case .alphabetical:
                            sortedKeys = pinnedPresent + remaining.sorted()
                    }
                } else {
                    switch order {
                        case .length:
                            sortedKeys = dict.keys.sorted {
                                $0.count < $1.count || ($0.count == $1.count && $0 < $1)
                            }
                        case .alphabetical:
                            sortedKeys = dict.keys.sorted()
                    }
                }
                output += "{\n"
                let childIndent = indent + 2
                for (i, key) in sortedKeys.enumerated() {
                    output += String(repeating: " ", count: childIndent)
                    output += "\""
                    output += escapeJSON(key)
                    output += "\" : "
                    dict[key]!.write(to: &output, indent: childIndent, sortBy: order)
                    if i < sortedKeys.count - 1 { output += "," }
                    output += "\n"
                }
                output += String(repeating: " ", count: indent)
                output += "}"
        }
    }

    private func escapeJSON(_ s: String) -> String {
        var result = ""
        result.reserveCapacity(s.count)
        for c in s.unicodeScalars {
            switch c {
                case "\"": result += "\\\""
                case "\\": result += "\\\\"
                case "\n": result += "\\n"
                case "\r": result += "\\r"
                case "\t": result += "\\t"
                case "\u{08}": result += "\\b"
                case "\u{0C}": result += "\\f"
                default:
                    result += c.value < 0x20
                        ? String(format: "\\u%04x", c.value)
                        : String(c)

            }
        }
        return result
    }
}
