// Adapted from kylef/JSONSchema.swift Copyright (c) 2015, Kyle Fuller. All rights reserved. BSD
// 3-Clause License. See https://github.com/kylef/JSONSchema.swift/blob/master/LICENSE

import Foundation

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
        var result = ""
        var first = true
        for component in components {
            if !first { result.append("/") }
            first = false

            for c in component {
                switch c {
                    case "~": result.append("~0")
                    case "/": result.append("~1")
                    default: result.append(c)
                }
            }
        }
        return result
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

        if case let .object(defs) = schema["$defs"] {
            for (key, value) in defs { store["#/$defs/\(key)"] = value }
        }
        self.store = store
    }

    func resolve(reference: String) -> JSONValue? { store[reference] }
}

// MARK: - Validation Context

/// Walks a JSON instance against a JSON Schema, collecting errors.
private struct ValidationContext {
    let resolver: RefResolver
    var instanceLocation = JSONPointer()
    var keywordLocation = JSONPointer(path: "#")

    init(resolver: RefResolver) { self.resolver = resolver }

    func error(_ message: String) -> SchemaValidationError {
        .init(
            message: message,
            instanceLocation: instanceLocation.path,
            keywordLocation: keywordLocation.path
        )
    }

    mutating func validate(instance: JSONValue, schema: JSONValue) -> [SchemaValidationError] {
        if case let .bool(flag) = schema { return flag ? [] : [error("Schema is false")] }
        guard case let .object(schemaDict) = schema else { return [] }
        return validate(instance: instance, schemaDict: schemaDict)
    }

    mutating func validate(
        instance: JSONValue,
        schemaDict: [String: JSONValue]
    ) -> [SchemaValidationError] {
        var errors: [SchemaValidationError] = []

        for (keyword, value) in schemaDict {
            keywordLocation.push(keyword)
            defer { keywordLocation.pop() }

            switch keyword {
                case "type": errors += validateType(value, instance: instance)
                case "properties": errors += validateProperties(value, instance: instance)
                case "additionalProperties":
                    errors += validateAdditionalProperties(
                        value, instance: instance, schema: schemaDict
                    )
                case "required": errors += validateRequired(value, instance: instance)
                case "enum": errors += validateEnum(value, instance: instance)
                case "allOf": errors += validateAllOf(value, instance: instance)
                case "oneOf": errors += validateOneOf(value, instance: instance)
                case "$ref": errors += validateRef(value, instance: instance)
                case "items": errors += validateItems(value, instance: instance)
                case "minimum": errors += validateMinimum(value, instance: instance)
                default: break
            }
        }

        return errors
    }

    // MARK: - Keyword Validators

    private func validateType(
        _ type: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        let types: [String]

        switch type {
            case let .string(single): types = [single]
            case let .array(array):
                types = array.compactMap { if case let .string(s) = $0 { s } else { nil } }
            default: return []
        }

        if types.contains(where: { instance.matches(schemaType: $0) }) { return [] }

        let typeList = types.map { "'\($0)'" }.joined(separator: ", ")
        return [error("'\(instance.displayDescription)' is not of type \(typeList)")]
    }

    private mutating func validateProperties(
        _ properties: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case let .object(instanceDict) = instance,
              case let .object(propertiesDict) = properties else { return [] }

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
        _ additionalProperties: JSONValue,
        instance: JSONValue,
        schema: [String: JSONValue]
    ) -> [SchemaValidationError] {
        guard case let .object(instanceDict) = instance else { return [] }

        var extraKeys = Set(instanceDict.keys)

        if case let .object(properties) = schema["properties"] {
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
        _ required: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case let .object(instanceDict) = instance,
              case let .array(requiredArray) = required else { return [] }

        return requiredArray.compactMap { element in
            guard case let .string(key) = element else { return nil }
            guard !instanceDict.keys.contains(key) else { return nil }
            return error("Required property '\(key)' is missing")
        }
    }

    private func validateEnum(
        _ enumValues: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case let .array(candidates) = enumValues else { return [] }
        if candidates.contains(instance) { return [] }
        let allowed = candidates.map { "'\($0.displayDescription)'" }.joined(separator: ", ")
        return [error("'\(instance.displayDescription)' is not one of: \(allowed)")]
    }

    private mutating func validateAllOf(
        _ allOf: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case let .array(schemas) = allOf else { return [] }
        return schemas.flatMap { validate(instance: instance, schema: $0) }
    }

    private mutating func validateOneOf(
        _ oneOf: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case let .array(schemas) = oneOf else { return [] }
        var validCount = 0

        for schema in schemas {
            // Use a copy so location state isn't polluted.
            var branch = self
            if branch.validate(instance: instance, schema: schema).isEmpty { validCount += 1 }
        }
        return validCount == 1
            ? []
            : [error("Exactly one schema in 'oneOf' must match, but \(validCount) matched")]
    }

    private mutating func validateRef(
        _ ref: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case let .string(refString) = ref,
              let resolved = resolver.resolve(reference: refString) else { return [] }
        return validate(instance: instance, schema: resolved)
    }

    private mutating func validateItems(
        _ items: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard case let .array(elements) = instance else { return [] }
        var errors: [SchemaValidationError] = []

        for (index, element) in elements.enumerated() {
            instanceLocation.push("\(index)")
            defer { instanceLocation.pop() }
            errors += validate(instance: element, schema: items)
        }
        return errors
    }

    private func validateMinimum(
        _ minimum: JSONValue,
        instance: JSONValue
    ) -> [SchemaValidationError] {
        guard let minVal = minimum.numericValue, let instVal = instance.numericValue else {
            return []
        }
        return instVal >= minVal
            ? []
            : [
                error(
                    "'\(instance.displayDescription)' is less than minimum '\(minimum.displayDescription)'"
                )
            ]
    }
}

// MARK: - Public API

/// Validates a JSON value against a JSON Schema (Draft 2020-12 subset).
///
/// Supports: `type` , `properties` , `additionalProperties` , `required` , `enum` , `allOf` ,
/// `oneOf` , `$ref` / `$defs` , `minimum` , `items` .
package func validateSchema(
    instance: JSONValue,
    schema: JSONValue
) -> [SchemaValidationError] {
    guard case let .object(schemaDict) = schema else { return [] }
    let resolver = RefResolver(schema: schemaDict)
    var context = ValidationContext(resolver: resolver)
    return context.validate(instance: instance, schema: schema)
}
