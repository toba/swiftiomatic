import ConfigurationKit
import Foundation

/// Heap-allocated wrapper to break the recursive value type cycle in
/// `JSONSchemaNode` (the `items` field references `JSONSchemaNode`).
final class Indirect<Value: Codable>: Codable {
    let value: Value
    init(_ value: Value) { self.value = value }
    convenience init(from decoder: any Decoder) throws {
        try self.init(Value(from: decoder))
    }
    func encode(to encoder: any Encoder) throws {
        try value.encode(to: encoder)
    }
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
    static func boolean(description: String, defaultValue: Bool) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = "boolean"
        node.description = description
        node.defaultValue = .bool(defaultValue)
        return node
    }

    static func integer(
        description: String,
        defaultValue: Int,
        minimum: Int? = nil
    ) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = "integer"
        node.description = description
        node.defaultValue = .int(defaultValue)
        node.minimum = minimum
        return node
    }

    static func string(description: String) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = "string"
        node.description = description
        return node
    }

    static func stringEnum(
        description: String,
        values: [String],
        defaultValue: String
    ) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = "string"
        node.description = "\(description) Options: \(values.joined(separator: ", "))."
        node.enumValues = values
        node.defaultValue = .string(defaultValue)
        return node
    }

    static func object(
        description: String,
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

    static func stringArray(
        description: String,
        defaultValue: [String]? = nil
    ) -> JSONSchemaNode {
        var node = JSONSchemaNode()
        node.type = "array"
        node.description = description
        var itemNode = JSONSchemaNode()
        itemNode.type = "string"
        node.items = Indirect(itemNode)
        if let defaultValue {
            node.defaultValue = .array(defaultValue.map { .string($0) })
        }
        return node
    }
}
