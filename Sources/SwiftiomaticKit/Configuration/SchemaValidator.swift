// Adapted from kylef/JSONSchema.swift
// Copyright (c) 2015, Kyle Fuller. All rights reserved.
// BSD 3-Clause License. See https://github.com/kylef/JSONSchema.swift/blob/master/LICENSE

import Foundation

// MARK: - JSON Value

/// A JSON value suitable for schema validation.
///
/// Uses a proper Swift enum to distinguish types without ObjC bridging.
/// `JSONDecoder` with `allowsJSON5` produces these directly.
package enum JSONValue: Sendable, Equatable {
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
        if let v = try? container.decode(Bool.self) {
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
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported JSON value"
                )
            )
        }
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}

extension JSONValue {
    /// Human-readable description for error messages.
    var displayDescription: String {
        switch self {
        case .string(let s): s
        case .int(let n): "\(n)"
        case .double(let n): "\(n)"
        case .bool(let b): b ? "true" : "false"
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
        case .int(let n): Double(n)
        case .double(let n): n
        default: nil
        }
    }
}

// MARK: - JSON Pointer

/// RFC 6901 JSON Pointer for tracking locations in a JSON document.
struct JSONPointer: Sendable {
    private var components: [String]

    init() { components = [""] }

    init(path: String) {
        components = path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map {
                $0.replacingOccurrences(of: "~1", with: "/")
                    .replacingOccurrences(of: "~0", with: "~")
            }
    }

    var path: String {
        components
            .map {
                $0.replacingOccurrences(of: "~", with: "~0")
                    .replacingOccurrences(of: "/", with: "~1")
            }
            .joined(separator: "/")
    }

    mutating func push(_ component: String) { components.append(component) }
    mutating func pop() { components.removeLast() }
}

// MARK: - Validation Error

/// A single schema validation error with location information.
package struct SchemaValidationError: Sendable {
    package let message: String
    package let instanceLocation: String
    package let keywordLocation: String
}

// MARK: - Ref Resolver

/// Resolves `$ref` references within a JSON Schema document.
private struct RefResolver: Sendable {
    let store: [String: JSONValue]

    init(schema: [String: JSONValue]) {
        var store: [String: JSONValue] = [:]
        if case .object(let defs) = schema["$defs"] {
            for (key, value) in defs {
                store["#/$defs/\(key)"] = value
            }
        }
        self.store = store
    }

    func resolve(reference: String) -> JSONValue? {
        store[reference]
    }
}

// MARK: - Validation Context

/// Walks a JSON instance against a JSON Schema, collecting errors.
private struct ValidationContext {
    let resolver: RefResolver
    var instanceLocation = JSONPointer()
    var keywordLocation = JSONPointer(path: "#")

    init(resolver: RefResolver) {
        self.resolver = resolver
    }

    func error(_ message: String) -> SchemaValidationError {
        SchemaValidationError(
            message: message,
            instanceLocation: instanceLocation.path,
            keywordLocation: keywordLocation.path
        )
    }

    mutating func validate(instance: JSONValue, schema: JSONValue) -> [SchemaValidationError] {
        if case .bool(let flag) = schema {
            return flag ? [] : [error("Schema is false")]
        }
        guard case .object(let schemaDict) = schema else { return [] }
        return validate(instance: instance, schemaDict: schemaDict)
    }

    mutating func validate(
        instance: JSONValue, schemaDict: [String: JSONValue]
    ) -> [SchemaValidationError] {
        var errors: [SchemaValidationError] = []

        for (keyword, value) in schemaDict {
            keywordLocation.push(keyword)
            defer { keywordLocation.pop() }

            switch keyword {
            case "type":
                errors += validateType(value, instance: instance)
            case "properties":
                errors += validateProperties(value, instance: instance)
            case "additionalProperties":
                errors += validateAdditionalProperties(
                    value, instance: instance, schema: schemaDict
                )
            case "required":
                errors += validateRequired(value, instance: instance)
            case "enum":
                errors += validateEnum(value, instance: instance)
            case "allOf":
                errors += validateAllOf(value, instance: instance)
            case "oneOf":
                errors += validateOneOf(value, instance: instance)
            case "$ref":
                errors += validateRef(value, instance: instance)
            case "items":
                errors += validateItems(value, instance: instance)
            case "minimum":
                errors += validateMinimum(value, instance: instance)
            default:
                break // Ignore metadata keywords ($schema, $id, title, description, default, $defs, etc.)
            }
        }

        return errors
    }

    // MARK: - Keyword Validators

    private func validateType(
        _ type: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        let types: [String]
        switch type {
        case .string(let single):
            types = [single]
        case .array(let array):
            types = array.compactMap { if case .string(let s) = $0 { s } else { nil } }
        default:
            return []
        }

        if types.contains(where: { instance.matches(schemaType: $0) }) {
            return []
        }

        let typeList = types.map { "'\($0)'" }.joined(separator: ", ")
        return [error("'\(instance.displayDescription)' is not of type \(typeList)")]
    }

    private mutating func validateProperties(
        _ properties: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case .object(let instanceDict) = instance,
              case .object(let propertiesDict) = properties
        else { return [] }

        var errors: [SchemaValidationError] = []
        for (key, value) in instanceDict {
            if let subschema = propertiesDict[key] {
                instanceLocation.push(key)
                defer { instanceLocation.pop() }
                errors += validate(instance: value, schema: subschema)
            }
        }
        return errors
    }

    private mutating func validateAdditionalProperties(
        _ additionalProperties: JSONValue, instance: JSONValue,
        schema: [String: JSONValue]
    ) -> [SchemaValidationError] {
        guard case .object(let instanceDict) = instance else { return [] }

        var extraKeys = Set(instanceDict.keys)
        if case .object(let properties) = schema["properties"] {
            extraKeys.subtract(properties.keys)
        }

        if case .bool(false) = additionalProperties, !extraKeys.isEmpty {
            return extraKeys.sorted().map { key in
                instanceLocation.push(key)
                defer { instanceLocation.pop() }
                return error("Additional property '\(key)' is not permitted")
            }
        }

        return []
    }

    private func validateRequired(
        _ required: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case .object(let instanceDict) = instance,
              case .array(let requiredArray) = required
        else { return [] }

        return requiredArray.compactMap { element in
            guard case .string(let key) = element else { return nil }
            guard !instanceDict.keys.contains(key) else { return nil }
            return error("Required property '\(key)' is missing")
        }
    }

    private func validateEnum(
        _ enumValues: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case .array(let candidates) = enumValues else { return [] }
        if candidates.contains(instance) { return [] }
        let allowed = candidates.map { "'\($0.displayDescription)'" }.joined(separator: ", ")
        return [error("'\(instance.displayDescription)' is not one of: \(allowed)")]
    }

    private mutating func validateAllOf(
        _ allOf: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case .array(let schemas) = allOf else { return [] }
        return schemas.flatMap { validate(instance: instance, schema: $0) }
    }

    private mutating func validateOneOf(
        _ oneOf: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case .array(let schemas) = oneOf else { return [] }
        var validCount = 0
        for schema in schemas {
            // Use a copy so location state isn't polluted.
            var branch = self
            if branch.validate(instance: instance, schema: schema).isEmpty {
                validCount += 1
            }
        }
        if validCount == 1 { return [] }
        return [error("Exactly one schema in 'oneOf' must match, but \(validCount) matched")]
    }

    private mutating func validateRef(
        _ ref: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case .string(let refString) = ref,
              let resolved = resolver.resolve(reference: refString)
        else { return [] }
        return validate(instance: instance, schema: resolved)
    }

    private mutating func validateItems(
        _ items: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case .array(let elements) = instance else { return [] }
        var errors: [SchemaValidationError] = []
        for (index, element) in elements.enumerated() {
            instanceLocation.push("\(index)")
            defer { instanceLocation.pop() }
            errors += validate(instance: element, schema: items)
        }
        return errors
    }

    private func validateMinimum(
        _ minimum: JSONValue, instance: JSONValue
    ) -> [SchemaValidationError] {
        guard let minVal = minimum.numericValue,
              let instVal = instance.numericValue
        else { return [] }
        if instVal >= minVal { return [] }
        return [error("'\(instance.displayDescription)' is less than minimum '\(minimum.displayDescription)'")]
    }
}

// MARK: - Public API

/// Validates a JSON value against a JSON Schema (Draft 2020-12 subset).
///
/// Supports: `type`, `properties`, `additionalProperties`, `required`,
/// `enum`, `allOf`, `oneOf`, `$ref`/`$defs`, `minimum`, `items`.
package func validateSchema(
    instance: JSONValue,
    schema: JSONValue
) -> [SchemaValidationError] {
    guard case .object(let schemaDict) = schema else { return [] }
    let resolver = RefResolver(schema: schemaDict)
    var context = ValidationContext(resolver: resolver)
    return context.validate(instance: instance, schema: schema)
}
