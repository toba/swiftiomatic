import Foundation
import ConfigurationKit

/// Heap-allocated wrapper to break the recursive value type cycle in `JSONSchemaNode` (the `items`
/// field references `JSONSchemaNode` ).
final class Indirect<Value: Codable>: Codable {
    let value: Value
    init(_ value: Value) { self.value = value }
    convenience init(from decoder: any Decoder) throws { try self.init(Value(from: decoder)) }
    func encode(to encoder: any Encoder) throws { try value.encode(to: encoder) }
}

/// A JSON Schema node. Encode to produce standard JSON Schema output.
struct JSONSchemaNode: Codable {
    var schema: String?
    var id: String?
    var title: String?
    var description: String?
    var type: String?
    var properties: [String: JSONSchemaNode]?
    var required: [String]?
    var additionalProperties: Bool?
    var unevaluatedProperties: Bool?
    var enumValues: [String]?
    var defaultValue: JSONValue?
    var minimum: Int?
    var oneOf: [JSONSchemaNode]?
    var allOf: [JSONSchemaNode]?
    var ref: String?
    var defs: [String: JSONSchemaNode]?
    var items: Indirect<JSONSchemaNode>?

    private enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case id = "$id"
        case title, description, type, properties, required
        case additionalProperties
        case unevaluatedProperties
        case enumValues = "enum"
        case defaultValue = "default"
        case minimum, oneOf, allOf
        case ref = "$ref"
        case defs = "$defs"
        case items
    }
}

// MARK: - Convenience constructors

extension JSONSchemaNode {
    /// A node of `type` carrying `description` and an optional literal default.
    private static func scalar(
        _ type: String,
        _ description: String,
        _ defaultValue: JSONValue? = nil
    ) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = type
        node.description = description
        node.defaultValue = defaultValue
        return node
    }

    static func boolean(description: String, defaultValue: Bool? = nil) -> JSONSchemaNode {
        scalar("boolean", description, defaultValue.map(JSONValue.bool))
    }

    static func integer(
        description: String,
        defaultValue: Int? = nil,
        minimum: Int? = nil
    ) -> JSONSchemaNode {
        var node = scalar("integer", description, defaultValue.map(JSONValue.int))
        node.minimum = minimum
        return node
    }

    static func string(description: String, defaultValue: String? = nil) -> JSONSchemaNode {
        scalar("string", description, defaultValue.map(JSONValue.string))
    }

    /// An array node whose elements match `items` .
    static func array(description: String, items: JSONSchemaNode) -> JSONSchemaNode {
        var node = scalar("array", description)
        node.items = Indirect(items)
        return node
    }

    /// - Parameter description: Prose explaining what the property controls. The legal values are
    ///   appended automatically as `Options: a, b, c.` Pass `nil` to omit the prose and emit only
    ///   the options list.
    static func stringEnum(
        description: String?,
        values: [String],
        defaultValue: String
    ) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = "string"
        let options = "Options: \(values.joined(separator: ", "))."
        let trimmed = description?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmed, !trimmed.isEmpty {
            node.description = "\(trimmed)\n\n\(options)"
        } else {
            node.description = options
        }
        node.enumValues = values
        node.defaultValue = .string(defaultValue)
        return node
    }

    static func object(
        description: String?,
        properties: [String: JSONSchemaNode],
        additionalProperties: Bool? = false
    ) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = "object"
        node.description = description
        node.properties = properties
        node.additionalProperties = additionalProperties
        return node
    }

    static func stringArray(description: String) -> JSONSchemaNode {
        // The item node carries no description, so the emitted schema stays as it was before the
        // convenience constructors landed.
        var itemNode = JSONSchemaNode()
        itemNode.type = "string"
        return .array(description: description, items: itemNode)
    }
}
