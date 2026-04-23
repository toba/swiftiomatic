import Foundation

/// An arbitrary JSON value used for `default` and other polymorphic schema fields.
enum JSONSchemaValue: Codable {
    case bool(Bool)
    case int(Int)
    case string(String)
    case array([JSONSchemaValue])
    case object([String: JSONSchemaValue])

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([JSONSchemaValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: JSONSchemaValue].self) {
            self = .object(v)
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode JSONSchemaValue"
                )
            )
        }
    }
}

/// A JSON Schema node. Encode to produce standard JSON Schema output.
///
/// Uses `[String: String]` for `items` to avoid recursive struct references
/// (our array items are always simple types like `"string"`).
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
    var defaultValue: JSONSchemaValue?
    var minimum: Int?
    var oneOf: [JSONSchemaNode]?
    var allOf: [JSONSchemaNode]?
    var ref: String?
    var defs: [String: JSONSchemaNode]?
    var items: [String: String]?

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
        node.items = ["type": "string"]
        if let defaultValue {
            node.defaultValue = .array(defaultValue.map { .string($0) })
        }
        return node
    }
}
